import { createTwoFilesPatch } from "diff";
import { relative, resolve } from "node:path";
import { createHash } from "node:crypto";

/**
 * Strip the leading "@" prefix that pi sometimes prepends to file paths
 * in tool call arguments (e.g. "@foo.txt" → "foo.txt").
 */
export function stripAtPrefix(p: string): string {
  return p.startsWith("@") ? p.slice(1) : p;
}

/**
 * Normalize a raw tool-input path into an absolute path and a cwd-relative
 * path suitable as a stable storage key.  Returns `null` when the resolved
 * path escapes `cwd` (e.g. `../../etc/passwd`).
 */
export function normalizeToolPath(
  cwd: string,
  raw: string,
): { absPath: string; relPath: string } | null {
  const cleaned = stripAtPrefix(raw);
  const absPath = resolve(cwd, cleaned);
  const rel = relative(cwd, absPath);

  // Reject paths that escape cwd
  if (rel.startsWith("..")) return null;

  const relPath = rel || cleaned;
  return { absPath, relPath };
}

/**
 * Count added (+) and removed (-) lines in a unified-diff string.
 *
 * The `diff` package's `createTwoFilesPatch` output is standard unified
 * format: `+` / `-` at column 0 for added / removed hunk lines.
 * Header lines (`+++`, `---`, `@@`) are skipped.
 */
export function countDiffLines(
  unifiedDiff: string,
): { added: number; removed: number } {
  let added = 0;
  let removed = 0;
  for (const line of unifiedDiff.split("\n")) {
    if (
      line.startsWith("+++ ") ||
      line.startsWith("--- ") ||
      line.startsWith("@@")
    )
      continue;
    if (line.startsWith("+")) added++;
    else if (line.startsWith("-")) removed++;
  }
  return { added, removed };
}

export function formatAddedRemovedPlain(added: number, removed: number): string {
  return `(+${added}/-${removed})`;
}

/**
 * Compute a unified patch (context: 3) from original -> current content.
 * `original` is `null` for created files.
 */
export function patchFromBaseline(
  displayPath: string,
  original: string | null,
  current: string,
): string {
  return createTwoFilesPatch(
    displayPath,
    displayPath,
    original ?? "",
    current,
    "",
    "",
    { context: 3 },
  );
}

/**
 * Check whether a buffer is *probably* binary by scanning the first 4096
 * bytes for a NUL byte (`\0`).  Returns `true` when the file should be
 * skipped by the extension.
 */
export function isProbablyBinary(buf: Buffer): boolean {
  const end = Math.min(buf.length, 4096);
  for (let i = 0; i < end; i++) {
    if (buf[i] === 0) return true;
  }
  return false;
}

/**
 * Compute a SHA-256 hex digest of `content`.
 */
export function computeHash(content: string): string {
  return createHash("sha256").update(content).digest("hex");
}

// ── Session entry constants ──────────────────────────────────────────────

export const ENTRY_BASELINE = "filechanges:baseline";
export const ENTRY_CLEAR = "filechanges:clear";
export const ENTRY_UNTRACK = "filechanges:untrack";

// ── Read-only view types (used by `--cwd` / `--json` inspection) ────────

/** One replayed baseline, keyed by cwd-relative path. */
export type BaselineRecord = {
  path: string; // relPath (normalized against the view's base cwd)
  absPath: string;
  originalHash: string | null; // null => created file
  createdAt: number;
};

/** A session custom entry as produced by `ctx.sessionManager.getBranch()`. */
export type CustomEntry = {
  type: string;
  customType?: string;
  data?: any;
};

/** One tracked file in a computed view. `diff` is always materialized. */
export type TrackedViewFile = {
  path: string;
  absPath: string;
  kind: "new" | "edited";
  originalContent: string | null;
  currentContent: string;
  added: number;
  removed: number;
  diff: string;
  updatedAt: number;
};

/** Injectable I/O for `computeTrackedView` (real fs in prod, in-memory in tests). */
export type ViewIO = {
  readCurrent: (absPath: string) => Promise<Buffer | null>;
  /** Recover original content for a hash (e.g. git show / on-disk cache). */
  resolveContent: (relPath: string, hash: string) => Promise<string | null>;
  now?: () => number;
};

/**
 * Replay session custom entries into baselines + in-memory original contents,
 * normalizing every stored path against `baseCwd`. This is the same replay
 * logic the live extension runs on `session_start`, but against an arbitrary
 * base directory — so the Commander can inspect a Marshal worktree
 * (`/tmp/pi-marshals/<session-id>-<id>`) without touching the current
 * session's state. Entries whose paths escape `baseCwd` are skipped.
 */
export function replayBaselines(
  entries: CustomEntry[],
  baseCwd: string,
): { baselines: Map<string, BaselineRecord>; contents: Map<string, string> } {
  const baselines = new Map<string, BaselineRecord>();
  const contents = new Map<string, string>();

  for (const entry of entries) {
    if (entry.type !== "custom") continue;

    if (entry.customType === ENTRY_CLEAR) {
      baselines.clear();
      contents.clear();
      continue;
    }

    if (entry.customType === ENTRY_BASELINE) {
      const data = entry.data;
      if (!data?.path) continue;
      const normalized = normalizeToolPath(baseCwd, data.path);
      if (!normalized) continue; // FC-C3: skip escaped paths
      const { absPath, relPath } = normalized;

      let hash: string | null;
      if (typeof data.originalHash === "string") {
        hash = data.originalHash;
      } else if (typeof data.originalContent === "string") {
        // Legacy format: migrate to hash and cache the inline content
        hash = computeHash(data.originalContent);
        contents.set(hash, data.originalContent);
      } else if (data.originalContent === null || data.originalHash === null) {
        hash = null; // created file
      } else {
        hash = null;
      }

      baselines.set(relPath, {
        path: relPath,
        absPath,
        originalHash: hash,
        createdAt: typeof data.timestamp === "number" ? data.timestamp : Date.now(),
      });
      continue;
    }

    if (entry.customType === ENTRY_UNTRACK) {
      const data = entry.data;
      if (!data?.path) continue;
      const normalized = normalizeToolPath(baseCwd, data.path);
      if (!normalized) continue;
      baselines.delete(normalized.relPath);
      continue;
    }
  }

  return { baselines, contents };
}

/**
 * Compute the tracked-file view for a set of replayed baselines: stat/read
 * each file on disk, diff against its original content, and report which
 * files pi has created/edited and by how much. Mirrors the live extension's
 * recompute logic, but stateless and deterministic (ordered by createdAt).
 *
 * - Created-then-deleted files stay visible as `edited` with empty content.
 * - Files reverted to their original content are excluded (not tracked).
 * - Binary files are skipped entirely.
 */
export async function computeTrackedView(
  baselines: Map<string, BaselineRecord>,
  contents: Map<string, string>,
  io: ViewIO,
): Promise<TrackedViewFile[]> {
  const now = io.now ?? Date.now;
  const files: TrackedViewFile[] = [];
  const ordered = [...baselines.values()].sort((a, b) => a.createdAt - b.createdAt);

  for (const bl of ordered) {
    // Resolve original content (in-memory cache, then injected resolver)
    let originalContent: string | null = null;
    if (bl.originalHash !== null) {
      originalContent = contents.get(bl.originalHash) ?? null;
      if (originalContent === null) {
        originalContent = await io.resolveContent(bl.path, bl.originalHash);
        if (originalContent !== null) {
          contents.set(bl.originalHash, originalContent);
        }
      }
    }

    // Read current content
    let current: string | null = null;
    try {
      const buf = await io.readCurrent(bl.absPath);
      if (buf !== null) {
        if (isProbablyBinary(buf)) continue; // FC-E1: skip binary files
        current = buf.toString("utf-8");
      }
    } catch {
      current = null;
    }

    if (bl.originalHash === null) {
      // File was created by pi
      if (current === null) {
        // FC-E2: created-then-deleted stays tracked as edited
        files.push({
          path: bl.path,
          absPath: bl.absPath,
          kind: "edited",
          originalContent: null,
          currentContent: "",
          added: 0,
          removed: 0,
          diff: "",
          updatedAt: now(),
        });
        continue;
      }
      const diff = patchFromBaseline(bl.path, null, current);
      const { added, removed } = countDiffLines(diff);
      files.push({
        path: bl.path,
        absPath: bl.absPath,
        kind: "new",
        originalContent: null,
        currentContent: current,
        added,
        removed,
        diff,
        updatedAt: now(),
      });
      continue;
    }

    // File existed before pi touched it
    if (current === null) {
      // Deleted after edit
      files.push({
        path: bl.path,
        absPath: bl.absPath,
        kind: "edited",
        originalContent: originalContent ?? "",
        currentContent: "",
        added: 0,
        removed: 0,
        diff: "",
        updatedAt: now(),
      });
      continue;
    }

    if (originalContent !== null && current === originalContent) {
      continue; // back to original — not tracked
    }

    const diff = patchFromBaseline(bl.path, originalContent ?? "", current);
    const { added, removed } = countDiffLines(diff);
    files.push({
      path: bl.path,
      absPath: bl.absPath,
      kind: "edited",
      originalContent,
      currentContent: current,
      added,
      removed,
      diff,
      updatedAt: now(),
    });
  }

  return files;
}

/** Aggregate counts over a view for machine-readable reporting. */
export function summarizeView(view: TrackedViewFile[]): {
  total: number;
  edited: number;
  created: number;
} {
  const summary = { total: view.length, edited: 0, created: 0 };
  for (const v of view) {
    if (v.kind === "new") summary.created++;
    else summary.edited++;
  }
  return summary;
}
