import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import {
  DynamicBorder,
  getMarkdownTheme,
  isEditToolResult,
  isToolCallEventType,
  isWriteToolResult,
} from "@earendil-works/pi-coding-agent";
import type { SelectItem } from "@earendil-works/pi-tui";
import { Container, Key, Markdown, SelectList, Text, matchesKey } from "@earendil-works/pi-tui";
import { readFile, writeFile, rm, mkdir, stat as fsStat } from "node:fs/promises";
import { dirname, isAbsolute, relative, resolve } from "node:path";
import { execFileSync } from "node:child_process";
import {
  normalizeToolPath,
  countDiffLines,
  formatAddedRemovedPlain,
  patchFromBaseline,
  isProbablyBinary,
  computeHash,
  ENTRY_BASELINE,
  ENTRY_CLEAR,
  ENTRY_UNTRACK,
  replayBaselines,
  computeTrackedView,
  summarizeView,
} from "./utils.ts";
import type { CustomEntry, TrackedViewFile } from "./utils.ts";

// ── Constants ──────────────────────────────────────────────────────────
const MAX_WIDGET_ROWS = 8;
const BASELINE_CACHE_DIR = ".pi/filechanges/baselines";
const RECOMPUTE_DEBOUNCE_MS = 50;

// ── Types ──────────────────────────────────────────────────────────────

type Baseline = {
  path: string; // normalized relPath
  absPath: string;
  originalHash: string | null; // null => created file
  createdAt: number;
};

type TrackedFile = {
  path: string;
  absPath: string;
  displayPath: string;
  originalContent: string | null;
  currentContent: string;
  diff: string; // lazily computed; empty string until the overlay requests it
  added: number;
  removed: number;
  kind: "new" | "edited";
  updatedAt: number;
  /** mtimeMs + size from last recompute, for FC-P3 skip detection */
  lastMtimeMs?: number;
  lastSize?: number;
};

type PendingSnapshot = {
  path: string;
  absPath: string;
  before: string | null;
  /** For write tools: the content the tool intends to write (from event.input.content) */
  writeContent?: string;
};

// ── Utility helpers that depend on TrackedFile / theme ─────────────────

function styleAddedRemovedForList(theme: any, text: string): string {
  const m = text.match(/^\+(\d+)\/\-(\d+)$/);
  if (!m) return theme.fg("muted", text);
  const added = Number(m[1]);
  const removed = Number(m[2]);
  const plus =
    added === 0 ? theme.fg("text", `+${added}`) : theme.fg("success", `+${added}`);
  const minus =
    removed === 0 ? theme.fg("text", `-${removed}`) : theme.fg("error", `-${removed}`);
  return plus + theme.fg("text", "/") + minus;
}

function formatStatus(tracked: Map<string, TrackedFile>, theme?: any): string | undefined {
  if (tracked.size === 0) return undefined;
  let edited = 0;
  let created = 0;
  for (const t of tracked.values()) {
    if (t.kind === "new") created++;
    else edited++;
  }
  if (!theme) return `\u0394 ${edited}  + ${created}`;
  return theme.fg("muted", `\u0394 ${edited}  + ${created}`);
}

function buildWidgetLines(
  tracked: Map<string, TrackedFile>,
  theme?: any,
): string[] | undefined {
  if (tracked.size === 0) return undefined;
  const items = [...tracked.values()].sort((a, b) => b.updatedAt - a.updatedAt);
  const lines: string[] = [];

  for (const t of items.slice(0, MAX_WIDGET_ROWS)) {
    const tag = t.kind === "new" ? "+" : "\u0394";

    if (!theme) {
      lines.push(`${tag} ${t.displayPath} ${formatAddedRemovedPlain(t.added, t.removed)}`);
      continue;
    }

    const prefix =
      theme.fg("muted", `${tag} `) + theme.fg("muted", `${t.displayPath} `);
    const plus =
      t.added === 0
        ? theme.fg("text", `+${t.added}`)
        : theme.fg("success", `+${t.added}`);
    const minus =
      t.removed === 0
        ? theme.fg("text", `-${t.removed}`)
        : theme.fg("error", `-${t.removed}`);
    const counts =
      theme.fg("text", "(") + plus + theme.fg("text", "/") + minus + theme.fg("text", ")");

    lines.push(prefix + counts);
  }
  if (items.length > MAX_WIDGET_ROWS) {
    lines.push(
      theme
        ? theme.fg("dim", `\u2026and ${items.length - MAX_WIDGET_ROWS} more`)
        : `\u2026and ${items.length - MAX_WIDGET_ROWS} more`,
    );
  }
  return lines;
}

async function ensureParentDir(absPath: string): Promise<void> {
  await mkdir(dirname(absPath), { recursive: true });
}

// ── Baseline content cache helpers (FC-P2 / FC-A2) ────────────────────

function gitRoot(cwd: string): string | null {
  try {
    const out = execFileSync("git", ["rev-parse", "--show-toplevel"], {
      cwd,
      encoding: "utf-8",
      stdio: "pipe",
    });
    return out.trim() || null;
  } catch {
    return null;
  }
}

function cacheDir(cwd: string): string {
  return resolve(cwd, BASELINE_CACHE_DIR);
}

async function storeBaselineContent(
  cwd: string,
  hash: string,
  content: string,
): Promise<void> {
  const dir = cacheDir(cwd);
  await mkdir(dir, { recursive: true });
  await writeFile(resolve(dir, hash), content, "utf-8");
}

/**
 * Try to recover the original file content for a given `hash`:
 *  1. git show HEAD:<repo-root-relative path> (fast, no disk ops) — the path
 *     is computed relative to the repository root so subdirectory cwds work,
 *     and the result is verified against the hash before it is trusted.
 *  2. .pi/filechanges/baselines/<hash> on disk
 * Returns null when recovery is impossible.
 */
async function resolveBaselineContent(
  cwd: string,
  relPath: string,
  hash: string,
): Promise<string | null> {
  // 1. git (repo-root-relative path so subdir cwds resolve correctly)
  const root = gitRoot(cwd);
  if (root) {
    const repoRel = relative(root, resolve(cwd, relPath));
    if (repoRel && !repoRel.startsWith("..") && !isAbsolute(repoRel)) {
      try {
        const out = execFileSync("git", ["show", `HEAD:${repoRel}`], {
          cwd,
          encoding: "utf-8",
          stdio: "pipe",
        });
        if (computeHash(out) === hash) return out;
      } catch {
        // file not in git HEAD — fall through to cache
      }
    }
  }

  // 2. on-disk cache
  try {
    const cached = await readFile(resolve(cacheDir(cwd), hash), "utf-8");
    if (computeHash(cached) === hash) return cached;
  } catch {
    // not in cache either
  }

  return null;
}

// ── Extension ──────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // ── In-memory state ──────────────────────────────────────────────────

  const baselines = new Map<string, Baseline>(); // key: relPath
  const tracked = new Map<string, TrackedFile>(); // key: relPath
  const pendingByToolCallId = new Map<string, PendingSnapshot>();
  /** hash → original content, populated eagerly on baseline creation / replay */
  const baselineContents = new Map<string, string>();

  function getOriginalContent(relPath: string): string | null {
    const bl = baselines.get(relPath);
    if (!bl) return null;
    if (bl.originalHash === null) return null; // created file
    return baselineContents.get(bl.originalHash) ?? null;
  }

  // ── UI helpers ───────────────────────────────────────────────────────

  function updateUi(ctx: any) {
    if (!ctx?.hasUI) return;
    ctx.ui.setStatus("filechanges", formatStatus(tracked, ctx.ui.theme));
    ctx.ui.setWidget("filechanges", buildWidgetLines(tracked, ctx.ui.theme));
  }

  // ── Recompute a single tracked file (used on session replay) ────────
  // FC-P3: skip if mtime+size unchanged since last recompute.

  async function recomputeTrackedFile(ctx: any, relPath: string) {
    const baseline = baselines.get(relPath);
    if (!baseline) return;

    // FC-P3: stat first
    let currentMtimeMs = 0;
    let currentSize = 0;
    try {
      const st = await fsStat(baseline.absPath);
      currentMtimeMs = st.mtimeMs;
      currentSize = st.size;
    } catch {
      // file doesn't exist
    }

    const existing = tracked.get(relPath);
    if (
      existing &&
      existing.lastMtimeMs === currentMtimeMs &&
      existing.lastSize === currentSize
    ) {
      // No disk change — keep existing entry, just bump updatedAt
      existing.updatedAt = Date.now();
      return;
    }

    const originalContent = getOriginalContent(relPath);

    let current: string | null;
    try {
      // FC-E1: binary guard
      const buf = await readFile(baseline.absPath);
      if (isProbablyBinary(buf)) {
        // Binary file — skip tracking
        tracked.delete(relPath);
        return;
      }
      current = buf.toString("utf-8");
    } catch {
      current = null;
    }

    if (baseline.originalHash === null) {
      // File was created by pi
      if (current === null) {
        // FC-E2: keep tracking created-then-deleted files as edited
        tracked.set(relPath, {
          path: baseline.path,
          absPath: baseline.absPath,
          displayPath: baseline.path,
          originalContent: null,
          currentContent: "",
          diff: "",
          added: 0,
          removed: 0,
          kind: "edited",
          updatedAt: Date.now(),
        });
        return;
      }

      const diff = patchFromBaseline(baseline.path, null, current);
      const { added, removed } = countDiffLines(diff);
      tracked.set(relPath, {
        path: baseline.path,
        absPath: baseline.absPath,
        displayPath: baseline.path,
        originalContent: null,
        currentContent: current,
        diff: "", // lazy
        added,
        removed,
        kind: "new",
        updatedAt: Date.now(),
        lastMtimeMs: currentMtimeMs,
        lastSize: currentSize,
      });
      return;
    }

    // File existed before pi touched it
    if (current === null) {
      // Deleted
      tracked.set(relPath, {
        path: baseline.path,
        absPath: baseline.absPath,
        displayPath: baseline.path,
        originalContent: originalContent ?? "",
        currentContent: "",
        diff: "",
        added: 0,
        removed: 0,
        kind: "edited",
        updatedAt: Date.now(),
      });
      return;
    }

    if (originalContent !== null && current === originalContent) {
      // Back to original — untrack
      tracked.delete(relPath);
      return;
    }

    // Diff from original — compute counts eagerly so widget is accurate;
    // full patch is lazy.
    const diff = patchFromBaseline(baseline.path, originalContent, current);
    const { added, removed } = countDiffLines(diff);
    tracked.set(relPath, {
      path: baseline.path,
      absPath: baseline.absPath,
      displayPath: baseline.path,
      originalContent,
      currentContent: current,
      diff: "", // lazy
      added,
      removed,
      kind: "edited",
      updatedAt: Date.now(),
      lastMtimeMs: currentMtimeMs,
      lastSize: currentSize,
    });
  }

  // ── Session log management ──────────────────────────────────────────

  function clearLog(ctx: ExtensionCommandContext, reason: "accept" | "decline") {
    baselines.clear();
    tracked.clear();
    pendingByToolCallId.clear();
    baselineContents.clear();
    pi.appendEntry(ENTRY_CLEAR, { timestamp: Date.now(), reason });
    updateUi(ctx);
  }

  /** FC-U3: untrack a single successfully reverted file. */
  function untrackOne(relPath: string) {
    baselines.delete(relPath);
    tracked.delete(relPath);
    pi.appendEntry(ENTRY_UNTRACK, { path: relPath, timestamp: Date.now() });
  }

  // ── Accept / Decline ────────────────────────────────────────────────

  async function declineAll(ctx: ExtensionCommandContext) {
    await ctx.waitForIdle();

    if (tracked.size === 0) {
      if (ctx.hasUI) ctx.ui.notify("filechanges: nothing to decline.", "info");
      return;
    }

    const force = (ctx as any).args?.includes("--decline-force") || (ctx as any).args?.includes("force");
    if (ctx.hasUI && !force) {
      const ok = await ctx.ui.confirm(
        "Decline pi changes?",
        "This will revert ALL currently logged pi changes (overwrite files / delete created files).",
      );
      if (!ok) return;
    } else if (!ctx.hasUI && !force) {
      throw new Error("Decline requires confirmation. Run: /filechanges-decline --decline-force");
    }

    const items = [...tracked.values()].sort((a, b) => b.updatedAt - a.updatedAt);
    let reverted = 0;
    const errors: string[] = [];

    for (const item of items) {
      try {
        // Guard: an edited file whose original content could not be recovered
        // (session restored without git/cache match) must NOT be deleted.
        const bl = baselines.get(item.path);
        const originalUnavailable =
          bl !== undefined && bl.originalHash !== null && item.originalContent === null;
        if (originalUnavailable) {
          errors.push(
            `${item.displayPath}: original content unavailable (cannot revert) — skipping`,
          );
          continue;
        }

        // FC-E3: check for external modifications before reverting
        if (item.originalContent !== null) {
          let currentDisk: string | null = null;
          try {
            currentDisk = await readFile(item.absPath, "utf-8");
          } catch {
            // file missing on disk — proceed with revert
          }
          if (currentDisk !== null && currentDisk !== item.currentContent) {
            if (force) {
              // Non-interactive force mode: warn and skip this file
              errors.push(
                `${item.displayPath}: file changed externally since last pi edit — skipping`,
              );
              continue;
            }
            // Interactive: warn and ask
            const ok = await ctx.ui.confirm(
              "File changed externally",
              `${item.displayPath} was modified outside of pi since the last edit. Reverting will overwrite those changes. Continue?`,
            );
            if (!ok) {
              errors.push(`${item.displayPath}: skipped (external changes detected)`);
              continue;
            }
          }
        }

        if (item.originalContent === null) {
          // Created file → delete it
          await rm(item.absPath, { force: true });
        } else {
          await ensureParentDir(item.absPath);
          await writeFile(item.absPath, item.originalContent, "utf-8");
        }
        // FC-U3: untrack only successfully reverted files
        untrackOne(item.path);
        reverted++;
      } catch (e: any) {
        errors.push(`${item.displayPath}: ${e?.message ?? String(e)}`);
      }
    }

    // FC-U3: if all files were reverted, clear the log; otherwise leave remaining tracked
    if (tracked.size === 0) {
      // All cleared — emit final CLEAR entry
      pi.appendEntry(ENTRY_CLEAR, { timestamp: Date.now(), reason: "decline" });
    }
    updateUi(ctx);

    if (ctx.hasUI) {
      if (errors.length === 0) {
        ctx.ui.notify(
          `filechanges: declined changes for ${reverted} file(s).`,
          "info",
        );
      } else {
        ctx.ui.notify(
          `filechanges: declined with ${errors.length} error(s). Run /filechanges to inspect; see console for details.`,
          "warning",
        );
        if (errors.length > 0)
          console.warn("[filechanges] decline errors:\n" + errors.join("\n"));
      }
    }
  }

  async function acceptAll(ctx: ExtensionCommandContext) {
    await ctx.waitForIdle();

    if (tracked.size === 0) {
      if (ctx.hasUI) ctx.ui.notify("filechanges: nothing to accept.", "info");
      return;
    }

    const force = (ctx as any).args?.includes("--accept-force") || (ctx as any).args?.includes("force");
    if (ctx.hasUI && !force) {
      const ok = await ctx.ui.confirm(
        "Accept pi changes?",
        "This will keep current files as-is and clear the modification log.",
      );
      if (!ok) return;
    } else if (!ctx.hasUI && !force) {
      throw new Error("Accept requires confirmation. Run: /filechanges-accept --accept-force");
    }

    const count = tracked.size;
    await clearLog(ctx, "accept");
    if (ctx.hasUI)
      ctx.ui.notify(`filechanges: accepted changes for ${count} file(s).`, "info");
  }

  // ── Per-file accept/decline helpers (FC-U1) ─────────────────────────

  async function acceptFile(ctx: ExtensionCommandContext, relPath: string): Promise<boolean> {
    const t = tracked.get(relPath);
    if (!t) return false;
    untrackOne(relPath);
    updateUi(ctx);
    return true;
  }

  async function declineFile(
    ctx: ExtensionCommandContext,
    relPath: string,
  ): Promise<boolean> {
    const t = tracked.get(relPath);
    if (!t) return false;

    try {
      // Guard: an edited file whose original content could not be recovered
      // must NOT be deleted (declining would destroy the file instead of reverting).
      const bl = baselines.get(relPath);
      const originalUnavailable =
        bl !== undefined && bl.originalHash !== null && t.originalContent === null;
      if (originalUnavailable) {
        if (ctx.hasUI)
          ctx.ui.notify(
            `filechanges: cannot revert ${t.displayPath} — original content unavailable (session restored without git/cache match)`,
            "warning",
          );
        return false;
      }

      // FC-E3: external-modification check
      if (t.originalContent !== null) {
        let currentDisk: string | null = null;
        try {
          currentDisk = await readFile(t.absPath, "utf-8");
        } catch {
          // missing on disk — proceed
        }
        if (currentDisk !== null && currentDisk !== t.currentContent) {
          const ok = await ctx.ui.confirm(
            "File changed externally",
            `${t.displayPath} was modified outside pi since the last edit. Reverting will overwrite those changes. Continue?`,
          );
          if (!ok) return false;
        }
      }

      if (t.originalContent === null) {
        await rm(t.absPath, { force: true });
      } else {
        await ensureParentDir(t.absPath);
        await writeFile(t.absPath, t.originalContent, "utf-8");
      }
      // FC-U3: only untrack on success
      untrackOne(relPath);
      updateUi(ctx);
      return true;
    } catch (e: any) {
      if (ctx.hasUI)
        ctx.ui.notify(
          `filechanges: failed to revert ${t.displayPath}: ${e?.message ?? String(e)}`,
          "error",
        );
      return false;
    }
  }

  // ── Inspect-mode helpers (--cwd / --json) ─────────────────────────
  // These power the pi-marshals Commander: querying a Marshal worktree
  // (or the live session) as machine-readable JSON, read-only, without
  // mutating the current session's in-memory state.

  function extractCwdArg(args: string[], baseCwd: string): string | null {
    const eq = args.find((a) => a.startsWith("--cwd="));
    if (eq) {
      const v = eq.slice("--cwd=".length);
      return v ? resolve(baseCwd, v) : null;
    }
    const i = args.indexOf("--cwd");
    if (i >= 0 && i + 1 < args.length && args[i + 1] && !args[i + 1].startsWith("--")) {
      return resolve(baseCwd, args[i + 1]);
    }
    return null;
  }

  /**
   * Replay session entries normalized against `baseCwd` (typically a Marshal
   * worktree) and compute the tracked-file view. Non-mutating: the live
   * `baselines`/`tracked` maps of the current session are untouched.
   */
  async function buildCwdView(ctx: any, baseCwd: string): Promise<TrackedViewFile[]> {
    const entries: CustomEntry[] = ctx.sessionManager
      .getBranch()
      .filter((e: any) => e.type === "custom");
    const { baselines, contents } = replayBaselines(entries, baseCwd);
    return computeTrackedView(baselines, contents, {
      readCurrent: async (absPath: string) => {
        try {
          return await readFile(absPath);
        } catch {
          return null;
        }
      },
      resolveContent: (relPath: string, hash: string) =>
        resolveBaselineContent(baseCwd, relPath, hash),
    });
  }

  // ── Parse command args ──────────────────────────────────────────────

  function parseCommandArgs(raw: string | undefined): string[] {
    if (!raw) return [];
    return raw
      .split(/\s+/g)
      .map((s) => s.trim())
      .filter(Boolean);
  }

  // ── Commands ────────────────────────────────────────────────────────

  pi.registerCommand("filechanges", {
    description: "Show files changed by pi and inspect diffs",
    handler: async (_args, ctx) => {
      const args = parseCommandArgs(_args);
      (ctx as any).args = args;

      await ctx.waitForIdle();

      // ── Read-only inspection modes (--cwd / --json) ────────────────
      const cwdOverride = extractCwdArg(args, ctx.cwd);
      if (cwdOverride || args.includes("--json")) {
        let view: TrackedViewFile[];
        if (cwdOverride) {
          view = await buildCwdView(ctx, cwdOverride);
        } else {
          view = [...tracked.values()]
            .sort((a, b) => b.updatedAt - a.updatedAt)
            .map((t) => ({
              path: t.path,
              absPath: t.absPath,
              kind: t.kind,
              originalContent: t.originalContent,
              currentContent: t.currentContent,
              added: t.added,
              removed: t.removed,
              diff:
                t.diff || patchFromBaseline(t.path, t.originalContent, t.currentContent),
              updatedAt: t.updatedAt,
            }));
        }

        if (args.includes("--json")) {
          console.log(
            JSON.stringify(
              { cwd: cwdOverride ?? ctx.cwd, summary: summarizeView(view), tracked: view },
              null,
              2,
            ),
          );
          return;
        }

        // --cwd without --json: plain-text listing of that worktree
        if (view.length === 0) {
          console.log("filechanges: no pi-made modifications recorded.");
          return;
        }
        console.log(
          view
            .map(
              (v) =>
                `${v.kind === "new" ? "+" : "\u0394"} ${v.path} ${formatAddedRemovedPlain(v.added, v.removed)}`,
            )
            .join("\n"),
        );
        return;
      }

      updateUi(ctx);

      // FC-U4: non-interactive force flags
      if (!ctx.hasUI) {
        const items = [...tracked.values()].sort((a, b) => b.updatedAt - a.updatedAt);
        if (args.includes("--accept-force")) {
          await acceptAll(ctx);
          return;
        }
        if (args.includes("--decline-force")) {
          await declineAll(ctx);
          return;
        }
        if (items.length === 0) {
          console.log("filechanges: no pi-made modifications recorded.");
          return;
        }
        const lines = buildWidgetLines(tracked) ?? [];
        console.log(lines.join("\n"));
        return;
      }

      // ── Interactive loop ──────────────────────────────────────

      while (true) {
        await ctx.waitForIdle();
        updateUi(ctx);

        const items = [...tracked.values()].sort((a, b) => b.updatedAt - a.updatedAt);
        if (items.length === 0) {
          ctx.ui.notify("filechanges: no pi-made modifications recorded.", "info");
          return;
        }

        const selectItems: SelectItem[] = [
          {
            value: "__accept__",
            label: "Accept changes (clear log)",
            description: "Keep current files",
          },
          {
            value: "__decline__",
            label: "Undo changes (revert)",
            description: "Restore original contents",
          },
          { value: "__sep__", label: "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500", description: "" },
          ...items.map((t) => ({
            value: t.path,
            label: `${t.kind === "new" ? "+" : "\u0394"} ${t.displayPath}`,
            description: `+${t.added}/-${t.removed}`,
          })),
        ];

        const picked = await ctx.ui.custom<string | null>(
          (tui, theme, _kb, done) => {
            const container = new Container();
            container.addChild(
              new DynamicBorder((s: string) => theme.fg("accent", s)),
            );
            container.addChild(
              new Text(
                theme.fg("accent", theme.bold("File changes")),
                1,
                0,
              ),
            );

            const list = new SelectList(
              selectItems,
              Math.min(14, selectItems.length),
              {
                selectedPrefix: (t) => theme.fg("accent", t),
                selectedText: (t) => theme.fg("accent", t),
                description: (t) => styleAddedRemovedForList(theme, t),
                scrollInfo: (t) => theme.fg("dim", t),
                noMatch: (t) => theme.fg("warning", t),
              },
            );

            list.onSelect = (item) => {
              if (item.value === "__sep__") return;
              done(item.value);
            };
            list.onCancel = () => done(null);
            container.addChild(list);

            container.addChild(
              new Text(
                theme.fg("dim", "\u2191\u2193 navigate \u2022 enter select \u2022 esc close"),
                1,
                0,
              ),
            );
            container.addChild(
              new DynamicBorder((s: string) => theme.fg("accent", s)),
            );

            return {
              render: (w) => container.render(w),
              invalidate: () => container.invalidate(),
              handleInput: (data) => {
                list.handleInput(data);
                tui.requestRender();
              },
            };
          },
          { overlay: true },
        );

        if (!picked) return;
        if (picked === "__accept__") {
          await acceptAll(ctx);
          return;
        }
        if (picked === "__decline__") {
          await declineAll(ctx);
          return;
        }

        const t = tracked.get(picked);
        if (!t) {
          ctx.ui.notify(
            "filechanges: entry not found (maybe log was cleared).",
            "warning",
          );
          continue;
        }

        // FC-P4: lazy diff — compute on demand
        const lazyDiff =
          t.diff ||
          patchFromBaseline(t.displayPath, t.originalContent, t.currentContent);
        const md =
          "```diff\n" + (lazyDiff.trimEnd() || "(no diff)") + "\n```";

        // ── Diff overlay with per-file accept/decline (FC-U1) ──────

        const diffChoice = await ctx.ui.custom<string | null>(
          (tui, theme, _kb, done) => {
            const container = new Container();
            container.addChild(
              new DynamicBorder((s: string) => theme.fg("accent", s)),
            );
            container.addChild(
              new Text(
                theme.fg("accent", theme.bold(t.displayPath)),
                1,
                0,
              ),
            );
            container.addChild(new Markdown(md, 1, 0, getMarkdownTheme()));
            container.addChild(
              new Text(
                theme.fg(
                  "dim",
                  "esc back  •  a = accept this file  •  d = decline this file",
                ),
                1,
                0,
              ),
            );
            container.addChild(
              new DynamicBorder((s: string) => theme.fg("accent", s)),
            );

            return {
              render: (w) => container.render(w),
              invalidate: () => container.invalidate(),
              handleInput: (data) => {
                if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) {
                  done(null);
                } else if (data === "a" || data === "A") {
                  done("___filechanges_accept___");
                } else if (data === "d" || data === "D") {
                  done("___filechanges_decline___");
                } else {
                  tui.requestRender();
                }
              },
            };
          },
          { overlay: true },
        );

        if (diffChoice === "___filechanges_accept___") {
          await acceptFile(ctx, t.path);
          if (ctx.hasUI)
            ctx.ui.notify(
              `Accepted changes for ${t.displayPath}.`,
              "info",
            );
        } else if (diffChoice === "___filechanges_decline___") {
          const ok = await declineFile(ctx, t.path);
          if (ok && ctx.hasUI)
            ctx.ui.notify(
              `Declined changes for ${t.displayPath}.`,
              "info",
            );
        }
        // Loop back to the modification log
      }
    },
  });

  pi.registerCommand("filechanges-accept", {
    description: "Accept pi-made changes (keeps files, clears log)",
    handler: async (args, ctx) => {
      (ctx as any).args = parseCommandArgs(args);
      await acceptAll(ctx);
    },
  });

  pi.registerCommand("filechanges-decline", {
    description: "Decline pi-made changes (reverts files, clears log)",
    handler: async (args, ctx) => {
      (ctx as any).args = parseCommandArgs(args);
      await declineAll(ctx);
    },
  });

  // ── Rebuild state from session entries (FC-E5 debounced) ────────────

  let rebuildGeneration = 0;
  let rebuildTimer: ReturnType<typeof setTimeout> | null = null;

  async function rebuildFromSession(ctx: any): Promise<void> {
    const gen = ++rebuildGeneration;

    // Debounce: wait 50ms, discard if a newer call supersedes this one
    if (rebuildTimer) clearTimeout(rebuildTimer);
    await new Promise<void>((resolve) => {
      rebuildTimer = setTimeout(() => {
        rebuildTimer = null;
        resolve();
      }, RECOMPUTE_DEBOUNCE_MS);
    });
    if (gen !== rebuildGeneration) return;

    baselines.clear();
    tracked.clear();
    pendingByToolCallId.clear();
    baselineContents.clear();

    // Replay custom entries on current branch
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "custom") continue;

      if (entry.customType === ENTRY_CLEAR) {
        baselines.clear();
        tracked.clear();
        baselineContents.clear();
        continue;
      }

      if (entry.customType === ENTRY_BASELINE) {
        const data = entry.data as any;
        if (!data?.path) continue;
        const normalized = normalizeToolPath(ctx.cwd, data.path);
        if (!normalized) continue; // FC-C3: skip escaped paths
        const { absPath, relPath } = normalized;

        let hash: string | null;
        let contentToCache: string | null = null;

        if (typeof data.originalHash === "string") {
          hash = data.originalHash;
        } else if (typeof data.originalContent === "string") {
          // Legacy format: migrate to hash
          hash = computeHash(data.originalContent);
          contentToCache = data.originalContent;
        } else if (data.originalContent === null || data.originalHash === null) {
          hash = null; // created file
        } else {
          hash = null;
        }

        if (hash !== null && contentToCache !== null) {
          baselineContents.set(hash, contentToCache);
        }

        baselines.set(relPath, {
          path: relPath,
          absPath,
          originalHash: hash,
          createdAt:
            typeof data.timestamp === "number" ? data.timestamp : Date.now(),
        });
        continue;
      }

      if (entry.customType === ENTRY_UNTRACK) {
        const data = entry.data as any;
        if (!data?.path) continue;
        const normalized = normalizeToolPath(ctx.cwd, data.path);
        if (!normalized) continue;
        baselines.delete(normalized.relPath);
        tracked.delete(normalized.relPath);
        continue;
      }
    }

    // Resolve original content for each baseline (git / cache dir)
    for (const [relPath, bl] of baselines) {
      if (bl.originalHash !== null && !baselineContents.has(bl.originalHash)) {
        const content = await resolveBaselineContent(
          ctx.cwd,
          bl.path,
          bl.originalHash,
        );
        if (content !== null) {
          baselineContents.set(bl.originalHash, content);
        }
      }
    }

    // RecomputedTrackedFile on replay
    for (const relPath of baselines.keys()) {
      await recomputeTrackedFile(ctx, relPath);
    }

    updateUi(ctx);
  }

  // ── Session events ──────────────────────────────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    await rebuildFromSession(ctx);
  });

  pi.on("session_tree", async (_event, ctx) => {
    await rebuildFromSession(ctx);
  });

  // ── Tool events ─────────────────────────────────────────────────────

  // FC-C1 + tool_call: snapshot before state + guard against path escape & binary files
  pi.on("tool_call", async (event, ctx) => {
    if (
      !isToolCallEventType("edit", event) &&
      !isToolCallEventType("write", event)
    )
      return;

    const rawPath = (event.input as any)?.path;
    if (!rawPath || typeof rawPath !== "string") return;

    // FC-C3: reject escaped paths
    const normalized = normalizeToolPath(ctx.cwd, rawPath);
    if (!normalized) {
      if (ctx.hasUI)
        ctx.ui.notify(
          `filechanges: skipping path outside project: ${rawPath}`,
          "warning",
        );
      return;
    }
    const { absPath, relPath } = normalized;

    // FC-E1: binary guard
    let before: string | null = null;
    try {
      const buf = await readFile(absPath);
      if (isProbablyBinary(buf)) {
        if (ctx.hasUI)
          ctx.ui.notify(
            `filechanges: skipping binary file: ${relPath}`,
            "info",
          );
        return;
      }
      before = buf.toString("utf-8");
    } catch {
      before = null; // file doesn't exist yet (will be created)
    }

    // For write tools: capture the to-be-written content
    const writeContent =
      isToolCallEventType("write", event) ? (event.input as any)?.content ?? "" : undefined;

    pendingByToolCallId.set(event.toolCallId, {
      path: relPath,
      absPath,
      before,
      writeContent,
    });

    // FC-C1: cleanup on abort
    ctx.signal?.addEventListener(
      "abort",
      () => {
        pendingByToolCallId.delete(event.toolCallId);
      },
      { once: true },
    );
  });

  // Hot-path tool_result handler (FC-P1 / FC-A1)
  pi.on("tool_result", async (event, ctx) => {
    if (event.isError) {
      pendingByToolCallId.delete(event.toolCallId);
      return;
    }

    if (!isEditToolResult(event) && !isWriteToolResult(event)) return;

    const pending = pendingByToolCallId.get(event.toolCallId);
    pendingByToolCallId.delete(event.toolCallId);
    if (!pending) return;

    // ── Create baseline if this is the first time we've seen this file ─
    if (!baselines.has(pending.path)) {
      const originalHash =
        pending.before !== null ? computeHash(pending.before) : null;

      baselines.set(pending.path, {
        path: pending.path,
        absPath: pending.absPath,
        originalHash,
        createdAt: Date.now(),
      });

      // Store baseline content so replay can always recover it, regardless
      // of git state (git show only matches when the working tree equals HEAD).
      if (originalHash !== null && pending.before !== null) {
        baselineContents.set(originalHash, pending.before);
        await storeBaselineContent(ctx.cwd, originalHash, pending.before);
      }

      pi.appendEntry(ENTRY_BASELINE, {
        path: pending.path,
        originalHash,
        timestamp: Date.now(),
      });
    }

    // ── Hot-path: compute added/removed counts without full read+diff ──

    const baseline = baselines.get(pending.path)!;
    let currentContent: string;
    let added: number;
    let removed: number;

    if (isEditToolResult(event)) {
      // FC-P1 / FC-A1: use pi's pre-computed diff for counts
      const editDiff = event.details?.diff ?? "";
      ({ added, removed } = countDiffLines(editDiff));
      // Still need currentContent for future comparisons; read once
      try {
        currentContent = await readFile(pending.absPath, "utf-8");
      } catch {
        currentContent = "";
      }
    } else {
      // Write tool: diff pending.before vs input content (no disk read!)
      currentContent = pending.writeContent ?? (event.input as any)?.content ?? "";
      if (pending.before !== null || currentContent !== "") {
        const wDiff = patchFromBaseline(
          pending.path,
          pending.before,
          currentContent,
        );
        ({ added, removed } = countDiffLines(wDiff));
      } else {
        added = 0;
        removed = 0;
      }
    }

    tracked.set(pending.path, {
      path: pending.path,
      absPath: pending.absPath,
      displayPath: pending.path,
      originalContent: getOriginalContent(pending.path),
      currentContent,
      diff: "", // FC-P4: lazy
      added,
      removed,
      kind: baseline.originalHash === null ? "new" : "edited",
      updatedAt: Date.now(),
    });

    // ── Back-to-baseline check ───────────────────────────────────────

    const original = getOriginalContent(pending.path);
    const backToOriginal =
      (original !== null &&
        currentContent === original) ||
      (original === null && currentContent === "");
    if (backToOriginal) {
      untrackOne(pending.path);
    }

    updateUi(ctx);
  });

  // FC-C1: drain pendingByToolCallId when agent settles
  pi.on("agent_settled", async (_event, _ctx) => {
    pendingByToolCallId.clear();
  });
}
