import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
	Editor,
	type EditorTheme,
	Key,
	SelectList,
	type SelectItem,
	Text,
	matchesKey,
	truncateToWidth,
	wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { Type } from "typebox";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface AskOption {
	label: string;
	value: string;
	description?: string;
}

interface DisplayOption extends AskOption {
	id: string;
	index?: number;
	isOther?: boolean;
	isSubmit?: boolean;
}

interface TextAnswer {
	type: "text";
	label: string;
	value: string;
}

interface OptionAnswer {
	type: "option";
	label: string;
	value: string;
	index: number;
}

interface OtherAnswer {
	type: "other";
	label: string;
	value: string;
}

type AskAnswer = TextAnswer | OptionAnswer | OtherAnswer;
type AskUserQuestionStatus = "answered" | "cancelled" | "unavailable" | "timed_out";
type AskUserQuestionMode = "text" | "single-select" | "multi-select";

interface AskUserQuestionResultDetails {
	status: AskUserQuestionStatus;
	question: string;
	context?: string;
	mode: AskUserQuestionMode;
	answers: AskAnswer[];
	message?: string;
}

// ---------------------------------------------------------------------------
// Parameter schema
// ---------------------------------------------------------------------------

const OptionSchema = Type.Object({
	label: Type.String({
		description:
			'Display label for the option. If you recommend an option, place it first and append "(Recommended)" to the label.',
	}),
	value: Type.Optional(
		Type.String({
			description: "Optional machine-readable value returned for the option. Defaults to the label.",
		}),
	),
	description: Type.Optional(Type.String({ description: "Optional extra detail shown below the option." })),
});

const AskUserQuestionParams = Type.Object({
	question: Type.String({
		description: "The single question to ask the user. Ask exactly one question per tool call.",
	}),
	details: Type.Optional(
		Type.String({
			description: "Optional extra context or instructions shown under the question.",
		}),
	),
	options: Type.Optional(
		Type.Array(OptionSchema, {
			description:
				"Optional multiple-choice options. Omit or pass an empty array for free-form text input. Users will always be able to choose Other and type a custom answer when options are provided.",
		}),
	),
	multiSelect: Type.Optional(
		Type.Boolean({
			description: "Set to true to allow multiple answers to be selected for a question.",
		}),
	),
	timeoutMs: Type.Optional(
		Type.Number({
			description: "Optional timeout in milliseconds after which the question auto-cancels.",
		}),
	),
});

// ---------------------------------------------------------------------------
// Option helpers
// ---------------------------------------------------------------------------

function normalizeOptions(
	options: Array<{ label: string; value?: string; description?: string }> | undefined,
): AskOption[] {
	const seenLabels = new Set<string>();
	const seenValues = new Set<string>();
	const result: AskOption[] = [];

	for (const option of options || []) {
		const label = option.label.trim();
		const value = option.value?.trim() || label;

		if (label.length === 0) continue;

		// AQ-E3: deduplicate by label+value
		if (seenLabels.has(label) || seenValues.has(value)) {
			console.warn(`ask_user_question: skipping duplicate option label="${label}" value="${value}"`);
			continue;
		}
		seenLabels.add(label);
		seenValues.add(value);

		result.push({
			label,
			value,
			description: option.description?.trim() || undefined,
		});
	}

	return result;
}

// AQ-E2: collision-proof Other label
function getOtherLabel(options: AskOption[]): string {
	const base = "Other (custom input)";
	const existingLabels = new Set(options.map((o) => o.label));
	if (!existingLabels.has(base)) return base;
	let i = 2;
	while (existingLabels.has(`${base} #${i}`)) i++;
	return `${base} #${i}`;
}

function createEditorTheme(theme: any): EditorTheme {
	return {
		borderColor: (s) => theme.fg("accent", s),
		selectList: {
			selectedPrefix: (t) => theme.fg("accent", t),
			selectedText: (t) => theme.fg("accent", t),
			description: (t) => theme.fg("muted", t),
			scrollInfo: (t) => theme.fg("dim", t),
			noMatch: (t) => theme.fg("warning", t),
		},
	};
}

function addWrapped(lines: string[], text: string, width: number, indent = ""): void {
	const contentWidth = Math.max(1, width - indent.length);
	for (const line of wrapTextWithAnsi(text, contentWidth)) {
		lines.push(truncateToWidth(`${indent}${line}`, width));
	}
}

function formatAnswerForModel(answer: AskAnswer): string {
	switch (answer.type) {
		case "text":
			return answer.label;
		case "other":
			return `Other: ${answer.label}`;
		case "option":
			return `${answer.index}. ${answer.label}`;
	}
}

function answerSortRank(answer: AskAnswer): number {
	switch (answer.type) {
		case "option":
			return answer.index;
		case "other":
			return Number.MAX_SAFE_INTEGER - 1;
		case "text":
			return Number.MAX_SAFE_INTEGER;
	}
}

function sortAnswers(answers: AskAnswer[]): AskAnswer[] {
	return [...answers].sort((a, b) => answerSortRank(a) - answerSortRank(b));
}

function buildStructuredResult(
	status: AskUserQuestionStatus,
	question: string,
	mode: AskUserQuestionMode,
	answers: AskAnswer[],
	context?: string,
	message?: string,
): AskUserQuestionResultDetails {
	return { status, question, context, mode, answers, message };
}

function cancelledResult(
	question: string,
	mode: AskUserQuestionMode,
	context?: string,
): AskUserQuestionResultDetails {
	return buildStructuredResult("cancelled", question, mode, [], context, "User cancelled the question");
}

function timedOutResult(
	question: string,
	mode: AskUserQuestionMode,
	context?: string,
	timeoutMs?: number,
): AskUserQuestionResultDetails {
	const message = timeoutMs ? `Question timed out after ${timeoutMs}ms` : "Question timed out";
	return buildStructuredResult("timed_out", question, mode, [], context, message);
}

function unavailableResult(
	question: string,
	mode: AskUserQuestionMode,
	message: string,
	context?: string,
): AskUserQuestionResultDetails {
	return buildStructuredResult("unavailable", question, mode, [], context, message);
}

function buildResult(
	question: string,
	context: string | undefined,
	mode: AskUserQuestionMode,
	answers: AskAnswer[],
): AskUserQuestionResultDetails {
	return buildStructuredResult("answered", question, mode, answers, context);
}

// ---------------------------------------------------------------------------
// Single-choice UI (SelectList, search/filter, "Other" inline Editor)
// ---------------------------------------------------------------------------

async function askSingleChoice(
	ctx: ExtensionContext,
	question: string,
	context: string | undefined,
	options: AskOption[],
): Promise<AskAnswer | null> {
	const otherLabel = getOtherLabel(options);
	const allOptions: DisplayOption[] = [
		...options.map((option, index) => ({ ...option, id: `option:${index}`, index: index + 1 })),
		{ id: "other", label: otherLabel, value: "__other__", isOther: true },
	];

	// AQ-E4: empty options guard
	if (allOptions.length === 0) return null;

	return ctx.ui.custom<AskAnswer | null>(
		(tui: any, theme: any, _kb: any, done: (result: AskAnswer | null) => void): any => {
			const editorTheme = createEditorTheme(theme);
			let editMode = false;
			let cachedLines: string[] | undefined;
			const editor = new Editor(tui, editorTheme);

			// AQ-C2: Focusable
			let _focused = false;

			// Keyboard filter/search
			let filterText = "";
			let filterTimer: ReturnType<typeof setTimeout> | undefined;

			// AQ-C1: idempotent done guard
			let settled = false;
			const safeDone = (result: AskAnswer | null) => {
				if (settled) return;
				settled = true;
				clearTimeout(filterTimer);
				done(result);
			};

			editor.onSubmit = (value) => {
				const trimmed = value.trim();
				if (!trimmed) return;
				safeDone({ type: "other", label: trimmed, value: trimmed });
			};

			// Teardown custom UI on abort (e.g. user presses Esc at agent level)
			ctx.signal?.addEventListener("abort", () => safeDone(null), { once: true });

			const selectItems: SelectItem[] = allOptions.map((opt) => ({
				value: opt.value,
				label: opt.isOther ? opt.label : `${opt.index}. ${opt.label}`,
				description: opt.description,
			}));

			const selectList = new SelectList(selectItems, 10, editorTheme.selectList);

			selectList.onSelect = (item: SelectItem) => {
				const sel = allOptions.find((opt) => opt.value === item.value);
				if (!sel) return;
				if (sel.isOther) {
					editMode = true;
					editor.setText("");
					cachedLines = undefined;
					tui.requestRender();
					return;
				}
				safeDone({ type: "option", label: sel.label, value: sel.value, index: sel.index! });
			};

			selectList.onCancel = () => safeDone(null);

			function handleInput(data: string) {
				if (editMode) {
					if (matchesKey(data, Key.escape)) {
						editMode = false;
						editor.setText("");
						cachedLines = undefined;
						tui.requestRender();
						return;
					}
					editor.handleInput(data);
					cachedLines = undefined;
					tui.requestRender();
					return;
				}

				// Printable filter before SelectList nav keys
				if (
					!matchesKey(data, Key.up) &&
					!matchesKey(data, Key.down) &&
					!matchesKey(data, Key.enter) &&
					!matchesKey(data, Key.escape)
				) {
					const ch = extractPrintableFilter(data);
					if (ch !== null) {
						filterText += ch;
						selectList.setFilter(filterText);
						clearTimeout(filterTimer);
						filterTimer = setTimeout(() => {
							filterText = "";
							selectList.setFilter("");
							cachedLines = undefined;
							tui.requestRender();
						}, 1500);
						cachedLines = undefined;
						tui.requestRender();
						return;
					}
				}

				selectList.handleInput(data);
				cachedLines = undefined;
				tui.requestRender();
			}

			function render(width: number): string[] {
				if (cachedLines) return cachedLines;
				const lines: string[] = [];
				const add = (text: string) => lines.push(truncateToWidth(text, width));

				add(theme.fg("accent", "─".repeat(width)));
				addWrapped(lines, theme.fg("text", ` ${question}`), width);
				if (context) {
					lines.push("");
					addWrapped(lines, theme.fg("muted", ` ${context}`), width);
				}
				lines.push("");

				if (editMode) {
					add(theme.fg("muted", " Write your custom answer:"));
					for (const line of editor.render(Math.max(1, width - 2))) add(` ${line}`);
					lines.push("");
					add(theme.fg("dim", " Enter to submit • Esc to go back"));
				} else {
					for (const line of selectList.render(width)) add(line);
					lines.push("");
					if (filterText) add(theme.fg("dim", ` Filter: "${filterText}"`));
					add(theme.fg("dim", " ↑↓ navigate • Enter select • type to filter • Esc cancel"));
				}

				add(theme.fg("accent", "─".repeat(width)));
				cachedLines = lines;
				return lines;
			}

			return {
				get focused() {
					return _focused;
				},
				set focused(v: boolean) {
					_focused = v;
					editor.focused = v;
				},
				render,
				invalidate: () => {
					cachedLines = undefined;
				},
				handleInput,
			};
		},
	);
}

// ---------------------------------------------------------------------------
// Multi-choice UI (checkbox rendering, submit, search/filter, "Other" inline)
// ---------------------------------------------------------------------------

async function askMultiChoice(
	ctx: ExtensionContext,
	question: string,
	context: string | undefined,
	options: AskOption[],
): Promise<AskAnswer[] | null> {
	const otherLabel = getOtherLabel(options);
	const choiceItems: DisplayOption[] = options.map((option, index) => ({
		...option,
		id: `option:${index}`,
		index: index + 1,
	}));
	const submitItem: DisplayOption = { id: "submit", label: "Submit", value: "__submit__", isSubmit: true };
	const allItems: DisplayOption[] = [
		...choiceItems,
		{ id: "other", label: otherLabel, value: "__other__", isOther: true },
		submitItem,
	];

	// AQ-E4: empty options guard
	if (allItems.length === 0) return null;

	return ctx.ui.custom<AskAnswer[] | null>(
		(tui: any, theme: any, _kb: any, done: (result: AskAnswer[] | null) => void): any => {
			const editorTheme = createEditorTheme(theme);
			let optionIndex = 0;
			let editMode = false;
			let cachedLines: string[] | undefined;
			const selected = new Map<string, AskAnswer>();
			const editor = new Editor(tui, editorTheme);

			// Filter/search
			let filterText = "";
			let filterTimer: ReturnType<typeof setTimeout> | undefined;

			// AQ-C2: Focusable
			let _focused = false;

			// AQ-C1: idempotent done guard
			let settled = false;
			const safeDone = (result: AskAnswer[] | null) => {
				if (settled) return;
				settled = true;
				clearTimeout(filterTimer);
				done(result);
			};

			editor.onSubmit = (value) => {
				const trimmed = value.trim();
				if (!trimmed) return;
				selected.set("other", { type: "other", label: trimmed, value: trimmed });
				editMode = false;
				refresh();
			};

			// Teardown custom UI on abort (e.g. user presses Esc at agent level)
			ctx.signal?.addEventListener("abort", () => safeDone(null), { once: true });

			function refresh() {
				cachedLines = undefined;
				tui.requestRender();
			}

			function toggleOption(item: DisplayOption) {
				if (selected.has(item.id)) {
					selected.delete(item.id);
				} else {
					selected.set(item.id, {
						type: "option",
						label: item.label,
						value: item.value,
						index: item.index!,
					});
				}
				refresh();
			}

			function getFilteredItems(): DisplayOption[] {
				if (!filterText) return allItems;
				const lower = filterText.toLowerCase();
				return allItems.filter(
					(item) =>
						item.label.toLowerCase().includes(lower) ||
						item.value.toLowerCase().includes(lower),
				);
			}

			function handleInput(data: string) {
				if (editMode) {
					if (matchesKey(data, Key.escape)) {
						editMode = false;
						editor.setText(selected.get("other")?.label || "");
						refresh();
						return;
					}
					editor.handleInput(data);
					refresh();
					return;
				}

				const filtered = getFilteredItems();

				if (matchesKey(data, Key.up)) {
					optionIndex = Math.max(0, optionIndex - 1);
					refresh();
					return;
				}
				if (matchesKey(data, Key.down)) {
					optionIndex = Math.min(filtered.length - 1, optionIndex + 1);
					refresh();
					return;
				}

				const current = filtered[optionIndex];

				if (matchesKey(data, Key.space)) {
					if (!current || current.isSubmit) return;
					if (current.isOther) {
						if (selected.has("other")) {
							selected.delete("other");
							refresh();
						} else {
							editMode = true;
							editor.setText("");
							refresh();
						}
						return;
					}
					toggleOption(current);
					return;
				}

				if (matchesKey(data, Key.enter)) {
					if (!current) return;
					if (current.isSubmit) {
						if (selected.size > 0) {
							safeDone(sortAnswers(Array.from(selected.values())));
						} else {
							// AQ-E1: Enter on Submit with 0 selections is not silent
							ctx.ui?.notify?.("Select at least one answer before submitting", "warning");
							refresh();
						}
						return;
					}
					if (current.isOther) {
						editMode = true;
						editor.setText(selected.get("other")?.label || "");
						refresh();
						return;
					}
					toggleOption(current);
					return;
				}

				if (matchesKey(data, Key.escape)) {
					safeDone(null);
					return;
				}

				// Printable character → filter
				const ch = extractPrintableFilter(data);
				if (ch !== null) {
					filterText += ch;
					optionIndex = 0;
					clearTimeout(filterTimer);
					filterTimer = setTimeout(() => {
						filterText = "";
						optionIndex = 0;
						refresh();
					}, 1500);
					refresh();
					return;
				}
			}

			function render(width: number): string[] {
				if (cachedLines) return cachedLines;

				const lines: string[] = [];
				const add = (text: string) => lines.push(truncateToWidth(text, width));

				add(theme.fg("accent", "─".repeat(width)));
				addWrapped(lines, theme.fg("text", ` ${question}`), width);
				if (context) {
					lines.push("");
					addWrapped(lines, theme.fg("muted", ` ${context}`), width);
				}
				lines.push("");

				const filtered = getFilteredItems();
				const safeIndex = filtered.length > 0 ? Math.min(optionIndex, filtered.length - 1) : 0;

				for (let i = 0; i < filtered.length; i++) {
					const item = filtered[i];
					const isFocused = i === safeIndex;
					const prefix = isFocused ? theme.fg("accent", "> ") : "  ";

					if (item.isSubmit) {
						const label =
							selected.size > 0
								? `✓ ${item.label} (${selected.size} selected)`
								: `○ ${item.label}`;
						const styled = isFocused
							? theme.fg("accent", label)
							: theme.fg(selected.size > 0 ? "success" : "dim", label);
						add(`${prefix}${styled}`);
						continue;
					}

					if (item.isOther) {
						const other = selected.get("other");
						const marker = other ? "[x]" : "[ ]";
						const suffix = other ? ` — ${other.label}` : "";
						const styled = isFocused
							? theme.fg("accent", `${marker} ${item.label}${suffix}`)
							: theme.fg(other ? "success" : "text", `${marker} ${item.label}${suffix}`);
						add(`${prefix}${styled}`);
						continue;
					}

					const checked = selected.has(item.id);
					const marker = checked ? "[x]" : "[ ]";
					const label = `${marker} ${item.index}. ${item.label}`;
					const styled = isFocused
						? theme.fg("accent", label)
						: theme.fg(checked ? "success" : "text", label);
					add(`${prefix}${styled}`);
					if (item.description) {
						addWrapped(lines, theme.fg("muted", item.description), width, "     ");
					}
				}

				if (editMode) {
					lines.push("");
					add(theme.fg("muted", " Write your custom answer:"));
					for (const line of editor.render(Math.max(1, width - 2))) add(` ${line}`);
					lines.push("");
					add(theme.fg("dim", " Enter to save • Esc to go back"));
				} else {
					lines.push("");
					if (filterText) add(theme.fg("dim", ` Filter: "${filterText}"`));
					if (selected.size === 0) {
						add(theme.fg("warning", " Select at least one answer before submitting."));
					}
					add(theme.fg("dim", " ↑↓ navigate • Space toggle • Enter edit/submit • type to filter • Esc cancel"));
				}

				add(theme.fg("accent", "─".repeat(width)));
				cachedLines = lines;
				return lines;
			}

			return {
				get focused() {
					return _focused;
				},
				set focused(v: boolean) {
					_focused = v;
					editor.focused = v;
				},
				render,
				invalidate: () => {
					cachedLines = undefined;
				},
				handleInput,
			};
		},
	);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Extract a single printable character from raw input data for filter/search.
 * Returns null if the data is not a simple printable key press.
 */
function extractPrintableFilter(data: string): string | null {
	if (data.length === 0) return null;
	if (data.startsWith("\x1b")) return null; // ESC sequences
	if (data === "\x7f" || data === "\b") return null; // Backspace
	if (data === "\r" || data === "\n") return null; // Enter
	if (data === "\t") return null; // Tab
	if (data === " ") return null; // Space (used for toggle in multi)

	if (data.length === 1) {
		const code = data.charCodeAt(0);
		if (code < 32 && code !== 0) return null; // control chars
		return data;
	}
	// Multi-byte UTF-8: accept
	return data;
}

// ---------------------------------------------------------------------------
// Mutex for serializing concurrent UI interactions
// ---------------------------------------------------------------------------

let uiLock: Promise<void> = Promise.resolve();

function withUILock<T>(fn: () => Promise<T>): Promise<T> {
	const prev = uiLock;
	let release: () => void;
	uiLock = new Promise<void>((r) => {
		release = r;
	});
	return prev.then(fn).finally(() => release!());
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function askUserQuestion(pi: ExtensionAPI) {
	pi.registerTool({
		name: "ask_user_question",
		// AQ-U5: human-readable label
		label: "Ask User Question",
		// AQ-U4: sequential execution prevents parallel UI conflicts
		executionMode: "sequential" as const,
		description:
			"Ask the user a single question and pause execution until they answer. Use this when requirements are ambiguous, user preferences are needed, a decision would materially affect implementation, or you need confirmation before proceeding. Ask exactly one question per tool call, and prefer multiple separate tool calls over bundling unrelated questions together.",
		promptSnippet:
			"Use ask_user_question to ask exactly one clarifying question, missing-requirement question, preference question, or decision question before continuing.",
		// AQ-U1: every guideline names the tool explicitly
		promptGuidelines: [
			"Ask exactly one question per ask_user_question tool call.",
			"If you need answers to multiple questions, make multiple separate ask_user_question tool calls instead of combining them into one prompt.",
			'Users will always be able to select "Other" to provide custom text input when ask_user_question options are provided.',
			"Use ask_user_question multiSelect: true only when you need multiple answers to the same question.",
			'If you recommend a specific option, make it the first option in the ask_user_question list and add "(Recommended)" at the end of the label.',
			"Prefer ask_user_question over guessing when requirements, preferences, or implementation choices are unclear.",
			"Use ask_user_question when multiple valid implementation paths exist and the preferred path depends on user choice.",
		],
		parameters: AskUserQuestionParams,

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const options = normalizeOptions(params.options);
			const context = params.details?.trim() || undefined;
			const mode: AskUserQuestionMode =
				options.length === 0 ? "text" : params.multiSelect ? "multi-select" : "single-select";
			const timeoutMs: number | undefined =
				typeof params.timeoutMs === "number" && params.timeoutMs > 0 ? params.timeoutMs : undefined;

			if (signal?.aborted) {
				return {
					content: [{ type: "text" as const, text: "Question cancelled before display" }],
					details: cancelledResult(params.question, mode, context),
				};
			}

			if (!ctx.hasUI) {
				return {
					content: [
						{ type: "text" as const, text: "ask_user_question requires interactive mode UI" },
					],
					details: unavailableResult(
						params.question,
						mode,
						"ask_user_question requires interactive mode UI",
						context,
					),
				};
			}

			// AQ-C1 + AQ-U3: abort handling with idempotent resolution + optional timeout
			return withUILock(async () => {
				let resolved = false;
				let timeoutId: ReturnType<typeof setTimeout> | undefined;

				function resolveOnce(cb: () => void) {
					if (resolved) return;
					resolved = true;
					if (timeoutId !== undefined) clearTimeout(timeoutId);
					if (signal) {
						try {
							signal.removeEventListener("abort", onAbort);
						} catch {
							/* best-effort */
						}
					}
					cb();
				}

				const onAbort = () => resolveOnce(() => {});

				if (signal) {
					signal.addEventListener("abort", onAbort, { once: true });
				}

				if (timeoutMs !== undefined) {
					timeoutId = setTimeout(() => resolveOnce(() => {}), timeoutMs);
				}

				if (mode === "text") {
					const editorTitle = context
						? `${params.question}\n\n${context}`
						: params.question;

					const answer = await ctx.ui.editor(editorTitle);

					if (resolved) {
						return {
							content: [
								{
									type: "text" as const,
									text: signal?.aborted
										? "Question cancelled"
										: timeoutMs !== undefined
											? `Question timed out after ${timeoutMs}ms`
											: "Question cancelled",
								},
							],
							details: signal?.aborted
								? cancelledResult(params.question, mode, context)
								: timedOutResult(params.question, mode, context, timeoutMs),
						};
					}

					if (answer === undefined) {
						return {
							content: [{ type: "text" as const, text: "User cancelled the question" }],
							details: cancelledResult(params.question, mode, context),
						};
					}

					return {
						content: [
							{
								type: "text" as const,
								text:
									answer.trim().length > 0
										? `User answered: ${answer.trim()}`
										: "User submitted an empty response",
							},
						],
						details: buildResult(params.question, context, mode, [
							{ type: "text", label: answer.trim(), value: answer.trim() },
						]),
					};
				}

				if (mode === "single-select") {
					// AQ-C1: for custom UI, Promise.race with abort/timeout promise
					const uiPromise = askSingleChoice(ctx, params.question, context, options);
					const cancelPromise = new Promise<null>((resolve) => {
						const cancel = () => resolveOnce(() => resolve(null));
						if (signal) {
							signal.addEventListener("abort", cancel, { once: true });
						}
						if (timeoutMs !== undefined) {
							timeoutId = setTimeout(cancel, timeoutMs);
						}
					});

					const answer = await Promise.race([uiPromise, cancelPromise]);

					if (resolved || answer === null) {
						return {
							content: [
								{
									type: "text" as const,
									text: signal?.aborted
										? "Question cancelled"
										: timeoutMs !== undefined && !answer
											? `Question timed out after ${timeoutMs}ms`
											: "User cancelled the question",
								},
							],
							details: signal?.aborted
								? cancelledResult(params.question, mode, context)
								: timeoutMs !== undefined && !answer
									? timedOutResult(params.question, mode, context, timeoutMs)
									: cancelledResult(params.question, mode, context),
						};
					}

					return {
						content: [
							{
								type: "text" as const,
								text: `User selected: ${formatAnswerForModel(answer)}`,
							},
						],
						details: buildResult(params.question, context, mode, [answer]),
					};
				}

				// multi-select
				const uiPromise = askMultiChoice(ctx, params.question, context, options);
				const cancelPromise = new Promise<null>((resolve) => {
					const cancel = () => resolveOnce(() => resolve(null));
					if (signal) {
						signal.addEventListener("abort", cancel, { once: true });
					}
					if (timeoutMs !== undefined) {
						timeoutId = setTimeout(cancel, timeoutMs);
					}
				});

				const answers = await Promise.race([uiPromise, cancelPromise]);

				if (resolved || answers === null) {
					return {
						content: [
							{
								type: "text" as const,
								text: signal?.aborted
									? "Question cancelled"
									: timeoutMs !== undefined && !answers
										? `Question timed out after ${timeoutMs}ms`
										: "User cancelled the question",
							},
						],
						details: signal?.aborted
							? cancelledResult(params.question, mode, context)
							: timeoutMs !== undefined && !answers
								? timedOutResult(params.question, mode, context, timeoutMs)
								: cancelledResult(params.question, mode, context),
					};
				}

				return {
					content: [
						{
							type: "text" as const,
							text: `User selected:\n${answers
								.map((a) => `- ${formatAnswerForModel(a)}`)
								.join("\n")}`,
						},
					],
					details: buildResult(params.question, context, mode, answers),
				};
			});
		},

		renderCall(args, theme) {
			const options = normalizeOptions(
				args.options as Array<{ label: string; value?: string; description?: string }> | undefined,
			);
			let text =
				theme.fg("toolTitle", theme.bold("ask_user_question ")) + theme.fg("muted", args.question);
			if (args.multiSelect) {
				text += theme.fg("dim", " [multi-select]");
			}
			if (options.length > 0) {
				const labels = [...options.map((o) => o.label), getOtherLabel(options)].join(", ");
				text += `\n${theme.fg("dim", `  Options: ${labels}`)}`;
			}
			return new Text(text, 0, 0);
		},

		renderResult(result, _options, theme) {
			const details = result.details as AskUserQuestionResultDetails | undefined;
			if (!details) {
				const first = result.content[0];
				return new Text(first?.type === "text" ? first.text : "", 0, 0);
			}

			if (details.status === "cancelled") {
				return new Text(theme.fg("warning", details.message || "Cancelled"), 0, 0);
			}

			if (details.status === "timed_out") {
				return new Text(theme.fg("warning", details.message || "Timed out"), 0, 0);
			}

			if (details.status === "unavailable") {
				return new Text(theme.fg("warning", details.message || "ask_user_question unavailable"), 0, 0);
			}

			const resultLines: string[] = [];
			for (const answer of details.answers) {
				switch (answer.type) {
					case "text":
						resultLines.push(
							`${theme.fg("success", "✓ ")}${theme.fg("accent", answer.label || "(empty response)")}`,
						);
						break;
					case "other":
						resultLines.push(
							`${theme.fg("success", "✓ ")}${theme.fg("muted", "Other: ")}${theme.fg("accent", answer.label)}`,
						);
						break;
					case "option":
						resultLines.push(
							`${theme.fg("success", "✓ ")}${theme.fg("accent", `${answer.index}. ${answer.label}`)}`,
						);
						break;
				}
			}

			// AQ-U6: render context when present
			if (details.context) {
				resultLines.push("");
				resultLines.push(theme.fg("dim", `  ${details.context}`));
			}

			return new Text(resultLines.join("\n"), 0, 0);
		},
	});
}
