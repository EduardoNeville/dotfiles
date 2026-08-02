import { describe, expect, test, beforeAll, afterAll } from "bun:test";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  ENTRY_BASELINE,
  ENTRY_CLEAR,
  ENTRY_UNTRACK,
  replayBaselines,
  computeTrackedView,
  summarizeView,
  computeHash,
} from "../utils.ts";
import type { CustomEntry, TrackedViewFile, ViewIO } from "../utils.ts";

// ── Helpers ─────────────────────────────────────────────────────────────

let dir: string;
let main: string;
let worktree: string;

beforeAll(async () => {
  dir = await mkdtemp(join(tmpdir(), "filechanges-view-"));
  main = join(dir, "main");
  worktree = join(dir, "worktree");
  await import("node:fs/promises").then((fs) => fs.mkdir(main, { recursive: true }));
  await import("node:fs/promises").then((fs) => fs.mkdir(worktree, { recursive: true }));
});

afterAll(async () => {
  await rm(dir, { recursive: true, force: true });
});

const entry = (customType: string, data: any): CustomEntry => ({
  type: "custom",
  customType,
  data,
});

function memoryIO(overrides?: Partial<ViewIO>): ViewIO {
  return {
    readCurrent: async (absPath: string) => {
      try {
        return Buffer.from(await import("node:fs/promises").then((fs) => fs.readFile(absPath)));
      } catch {
        return null;
      }
    },
    resolveContent: async () => null,
    ...overrides,
  };
}

// ── replayBaselines ─────────────────────────────────────────────────────

describe("replayBaselines", () => {
  test("baseline entry resolves path against base cwd", () => {
    const { baselines } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "src/a.ts", originalHash: "abc123", timestamp: 42 })],
      worktree,
    );
    expect(baselines.size).toBe(1);
    const bl = baselines.get("src/a.ts")!;
    expect(bl.absPath).toBe(join(worktree, "src/a.ts"));
    expect(bl.originalHash).toBe("abc123");
    expect(bl.createdAt).toBe(42);
  });

  test("legacy baseline with inline originalContent migrates to hash + caches content", () => {
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "a.txt", originalContent: "hello" })],
      main,
    );
    const bl = baselines.get("a.txt")!;
    expect(bl.originalHash).toBe(computeHash("hello"));
    expect(contents.get(computeHash("hello"))).toBe("hello");
  });

  test("created-file baseline (null hash) stays null", () => {
    const { baselines } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "new.ts", originalHash: null })],
      main,
    );
    expect(baselines.get("new.ts")!.originalHash).toBeNull();
  });

  test("entry whose path escapes base cwd is skipped (FC-C3)", () => {
    const { baselines } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "../../etc/passwd", originalHash: "x" })],
      main,
    );
    expect(baselines.size).toBe(0);
  });

  test("entries recorded in a worktree replay correctly with base cwd = worktree", () => {
    // Simulates the marshal scenario: tool events recorded with cwd = worktree,
    // then the Commander replays them with --cwd <worktree>.
    const { baselines } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "src/auth.ts", originalHash: "h1", timestamp: 1 })],
      worktree,
    );
    const bl = baselines.get("src/auth.ts")!;
    expect(bl.absPath).toBe(join(worktree, "src/auth.ts"));
  });

  test("entries recorded in a worktree replayed under the wrong cwd silently misresolve", () => {
    // Important constraint: paths that don't escape under the wrong cwd do NOT
    // get filtered — "src/auth.ts" recorded in the worktree replays as
    // <main>/src/auth.ts. The Commander must therefore pass the exact worktree
    // cwd that the entries were recorded in (this is why --cwd matters).
    const { baselines } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "src/auth.ts", originalHash: "h1" })],
      main,
    );
    expect(baselines.size).toBe(1);
    expect(baselines.get("src/auth.ts")!.absPath).toBe(join(main, "src/auth.ts"));
  });

  test("untrack entry removes a baseline", () => {
    const { baselines } = replayBaselines(
      [
        entry(ENTRY_BASELINE, { path: "a.txt", originalHash: "h1" }),
        entry(ENTRY_UNTRACK, { path: "a.txt" }),
      ],
      main,
    );
    expect(baselines.size).toBe(0);
  });

  test("clear entry resets everything (including cached contents)", () => {
    const { baselines, contents } = replayBaselines(
      [
        entry(ENTRY_BASELINE, { path: "a.txt", originalContent: "legacy" }),
        entry(ENTRY_CLEAR, {}),
        entry(ENTRY_BASELINE, { path: "b.txt", originalHash: "h2" }),
      ],
      main,
    );
    expect(baselines.size).toBe(1);
    expect(baselines.has("a.txt")).toBe(false);
    expect(baselines.has("b.txt")).toBe(true);
    expect(contents.size).toBe(0);
  });

  test("non-custom entries are ignored", () => {
    const { baselines } = replayBaselines(
      [{ type: "message", customType: undefined, data: {} } as any],
      main,
    );
    expect(baselines.size).toBe(0);
  });
});

// ── computeTrackedView ──────────────────────────────────────────────────

describe("computeTrackedView", () => {
  test("created file with current content on disk -> kind new, counts lines, materialized diff", async () => {
    await writeFile(join(worktree, "new.ts"), "line 1\nline 2\n");
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "new.ts", originalHash: null, timestamp: 1 })],
      worktree,
    );
    const view = await computeTrackedView(baselines, contents, memoryIO());
    expect(view).toHaveLength(1);
    const v = view[0];
    expect(v.kind).toBe("new");
    expect(v.currentContent).toBe("line 1\nline 2\n");
    expect(v.added).toBe(2);
    expect(v.removed).toBe(0);
    expect(v.diff).toContain("+line 1");
  });

  test("created file that was deleted afterwards stays tracked as edited (FC-E2)", async () => {
    // No file on disk
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "gone.ts", originalHash: null, timestamp: 1 })],
      worktree,
    );
    const view = await computeTrackedView(baselines, contents, memoryIO());
    expect(view).toHaveLength(1);
    expect(view[0].kind).toBe("edited");
    expect(view[0].currentContent).toBe("");
    expect(view[0].added).toBe(0);
  });

  test("edited file differs from original -> kind edited with counts", async () => {
    const original = "alpha\nbeta\ngamma\n";
    await writeFile(join(worktree, "edit.ts"), "alpha\nBETA\ngamma\ndelta\n");
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "edit.ts", originalHash: computeHash(original), timestamp: 1 })],
      worktree,
    );
    contents.set(computeHash(original), original);
    const view = await computeTrackedView(baselines, contents, memoryIO());
    expect(view).toHaveLength(1);
    expect(view[0].kind).toBe("edited");
    expect(view[0].added).toBe(2); // BETA + delta
    expect(view[0].removed).toBe(1); // beta
    expect(view[0].diff).toContain("-beta");
  });

  test("file reverted to its original content is excluded", async () => {
    const original = "same\n";
    await writeFile(join(worktree, "same.ts"), original);
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "same.ts", originalHash: computeHash(original), timestamp: 1 })],
      worktree,
    );
    contents.set(computeHash(original), original);
    const view = await computeTrackedView(baselines, contents, memoryIO());
    expect(view).toHaveLength(0);
  });

  test("edited file deleted on disk -> tracked as edited with empty content", async () => {
    const original = "delete me\n";
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "deleted.ts", originalHash: computeHash(original), timestamp: 1 })],
      worktree,
    );
    contents.set(computeHash(original), original);
    const view = await computeTrackedView(baselines, contents, memoryIO());
    expect(view).toHaveLength(1);
    expect(view[0].kind).toBe("edited");
    expect(view[0].currentContent).toBe("");
  });

  test("binary file on disk is skipped (FC-E1)", async () => {
    const binary = Buffer.from([0x48, 0x00, 0x65, 0x6c]);
    await import("node:fs/promises").then((fs) => fs.writeFile(join(worktree, "bin.dat"), binary));
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "bin.dat", originalHash: "h", timestamp: 1 })],
      worktree,
    );
    contents.set("h", "not relevant");
    const view = await computeTrackedView(baselines, contents, memoryIO());
    expect(view).toHaveLength(0);
  });

  test("original content resolved via injected resolver when not cached", async () => {
    const original = "cached elsewhere\n";
    await writeFile(join(worktree, "via-resolver.ts"), "cached elsewhere\nCHANGED\n");
    const { baselines, contents } = replayBaselines(
      [entry(ENTRY_BASELINE, { path: "via-resolver.ts", originalHash: "h-remote", timestamp: 1 })],
      worktree,
    );
    const io = memoryIO({
      resolveContent: async (relPath, hash) =>
        hash === "h-remote" ? original : null,
    });
    const view = await computeTrackedView(baselines, contents, io);
    expect(view).toHaveLength(1);
    expect(view[0].kind).toBe("edited");
    expect(view[0].added).toBe(1);
    expect(contents.get("h-remote")).toBe(original); // cached back for later use
  });

  test("output is deterministic: ordered by createdAt", async () => {
    await writeFile(join(worktree, "z.ts"), "z\n");
    await writeFile(join(worktree, "a.ts"), "a\n");
    const { baselines, contents } = replayBaselines(
      [
        entry(ENTRY_BASELINE, { path: "z.ts", originalHash: null, timestamp: 10 }),
        entry(ENTRY_BASELINE, { path: "a.ts", originalHash: null, timestamp: 5 }),
      ],
      worktree,
    );
    const view = await computeTrackedView(baselines, contents, memoryIO());
    expect(view.map((v) => v.path)).toEqual(["a.ts", "z.ts"]);
  });
});

// ── summarizeView ───────────────────────────────────────────────────────

describe("summarizeView", () => {
  test("aggregates total/edited/created", () => {
    const view: TrackedViewFile[] = [
      {
        path: "a.ts",
        absPath: "a",
        kind: "new",
        originalContent: null,
        currentContent: "x",
        added: 1,
        removed: 0,
        diff: "",
        updatedAt: 1,
      },
      {
        path: "b.ts",
        absPath: "b",
        kind: "edited",
        originalContent: "y",
        currentContent: "z",
        added: 1,
        removed: 1,
        diff: "",
        updatedAt: 1,
      },
    ];
    expect(summarizeView(view)).toEqual({ total: 2, edited: 1, created: 1 });
  });

  test("empty view", () => {
    expect(summarizeView([])).toEqual({ total: 0, edited: 0, created: 0 });
  });
});
