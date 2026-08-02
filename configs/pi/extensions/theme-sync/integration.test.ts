/**
 * Real-filesystem integration tests for theme-sync core (no pi runtime needed).
 *
 * Uses a temp state dir, real `fs.watch` (falling back to polling if the
 * environment can't watch), and real file IO. Verifies the acceptance behavior:
 * flipping ~/.local/state/theme produces log lines in theme-sync.log, atomic
 * replace is caught, garbage/missing content never crashes, and identical
 * values are not re-applied.
 */
import { describe, expect, test } from "bun:test";
import { appendFile, mkdir, mkdtemp, readFile, rename, rm, writeFile } from "node:fs/promises";
import { watch as fsWatch } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import {
  createThemeSync,
  type ThemeName,
  type WatchDir,
} from "./sync.ts";

const sleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

async function waitFor(
  predicate: () => boolean,
  timeoutMs = 8000,
  stepMs = 25,
): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (predicate()) return true;
    await sleep(stepMs);
  }
  return predicate();
}

const readText = async (path: string): Promise<string | null> => {
  try {
    return await readFile(path, "utf-8");
  } catch {
    return null;
  }
};

const appendLine = async (path: string, line: string): Promise<void> => {
  await mkdir(dirname(path), { recursive: true });
  await appendFile(path, `${line}\n`, "utf-8");
};

const watchDir: WatchDir = (dir, handlers) => {
  try {
    const watcher = fsWatch(dir, { persistent: true, encoding: "utf8" }, (eventType, filename) => {
      handlers.onEvent(eventType ?? "", filename ?? null);
    });
    watcher.on("error", (error) => handlers.onError(error));
    return { close: () => watcher.close() };
  } catch {
    return null; // → polling fallback
  }
};

const LOG_LINE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z (?:\(none\)|dark|light) -> (?:dark|light)$/;

describe("theme-sync real-fs integration", () => {
  test("flips, atomic-replace, dedupe, garbage, and missing file", async () => {
    const root = await mkdtemp(join(tmpdir(), "theme-sync-int-"));
    const stateDir = join(root, "state");
    const stateFile = join(stateDir, "theme");
    const logFile = join(stateDir, "theme-sync.log");
    await mkdir(stateDir, { recursive: true });
    await writeFile(stateFile, "dark", "utf-8");

    const applied: ThemeName[] = [];
    const setTheme = (theme: ThemeName) => {
      applied.push(theme);
      return true;
    };

    const controller = createThemeSync({
      stateFile,
      logFile,
      readText,
      appendLine,
      watchDir,
      setTheme,
      pollIntervalMs: 150, // small so the polling fallback is fast too
      debounceMs: 40,
      onError: (error, context) => console.warn(`[test] ${context}:`, error),
    });

    await controller.start();
    try {
      // 1. Initial apply.
      expect(await waitFor(() => applied.length >= 1)).toBe(true);
      expect(applied[0]).toBe("dark");

      // 2. In-place flip dark → light.
      await writeFile(stateFile, "light", "utf-8");
      expect(await waitFor(() => applied.length >= 2)).toBe(true);
      expect(applied[1]).toBe("light");

      // 3. Same value again → no re-apply.
      await writeFile(stateFile, "light", "utf-8");
      await sleep(600);
      expect(applied.length).toBe(2);

      // 4. Atomic-write replacement light → dark (write temp + rename over).
      const tmpFile = join(stateDir, "theme.tmp");
      await writeFile(tmpFile, "dark", "utf-8");
      await rename(tmpFile, stateFile);
      expect(await waitFor(() => applied.length >= 3)).toBe(true);
      expect(applied[2]).toBe("dark");

      // 5. Garbage content → no apply, no crash.
      await writeFile(stateFile, "chartreuse\n", "utf-8");
      await sleep(600);
      expect(applied.length).toBe(3);
      expect(controller.appliedTheme).toBe("dark");

      // 6. Missing file → no apply, no crash.
      await rm(stateFile, { force: true });
      await sleep(600);
      expect(applied.length).toBe(3);

      // 7. Verification evidence: one log line per applied switch.
      const log = await readText(logFile);
      expect(log).not.toBeNull();
      const lines = log!.trim().split("\n").filter(Boolean);
      expect(lines).toHaveLength(3);
      for (const line of lines) expect(line).toMatch(LOG_LINE);
      expect(lines[0]).toContain("(none) -> dark");
      expect(lines[1]).toContain("dark -> light");
      expect(lines[2]).toContain("light -> dark");
    } finally {
      controller.stop();
      await rm(root, { recursive: true, force: true });
    }
  }, 20000);

  test("polling fallback alone drives updates when fs.watch is unavailable", async () => {
    const root = await mkdtemp(join(tmpdir(), "theme-sync-poll-"));
    const stateDir = join(root, "state");
    const stateFile = join(stateDir, "theme");
    const logFile = join(stateDir, "theme-sync.log");
    await mkdir(stateDir, { recursive: true });
    await writeFile(stateFile, "dark", "utf-8");

    const applied: ThemeName[] = [];
    const controller = createThemeSync({
      stateFile,
      logFile,
      readText,
      appendLine,
      watchDir: () => null, // force polling
      setTheme: (theme) => (applied.push(theme), true),
      pollIntervalMs: 100,
      debounceMs: 20,
    });

    await controller.start();
    try {
      expect(controller.isWatching()).toBe(false);
      expect(controller.isPolling()).toBe(true);
      expect(await waitFor(() => applied.length >= 1)).toBe(true);

      await writeFile(stateFile, "light", "utf-8");
      expect(await waitFor(() => applied.length >= 2)).toBe(true);
      expect(applied[1]).toBe("light");
    } finally {
      controller.stop();
      await rm(root, { recursive: true, force: true });
    }
  }, 20000);
});
