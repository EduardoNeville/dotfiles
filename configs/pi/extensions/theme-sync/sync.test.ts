/**
 * Unit tests for the theme-sync core — runs under `bun test` WITHOUT the pi
 * runtime. All file IO, watcher, timers, and theme-setter behavior is faked.
 */
import { describe, expect, test } from "bun:test";
import {
  createThemeSync,
  parseTheme,
  resolveStatePaths,
  type ThemeName,
  type ThemeSyncDeps,
  type WatchDir,
  type WatchHandlers,
} from "./sync.ts";

// ── Fake harness ────────────────────────────────────────────────────────────

const FIXED_DATE = new Date("2026-01-02T03:04:05.678Z");

function createFakeTimers() {
  let nextId = 1;
  const timeouts = new Map<number, () => void>();
  const intervals = new Map<number, () => void>();
  return {
    setTimeoutFn: ((fn: () => void) => {
      const id = nextId++;
      timeouts.set(id, fn);
      return id;
    }) as unknown as typeof setTimeout,
    clearTimeoutFn: ((id: number) => {
      timeouts.delete(id);
    }) as unknown as typeof clearTimeout,
    setIntervalFn: ((fn: () => void) => {
      const id = nextId++;
      intervals.set(id, fn);
      return id;
    }) as unknown as typeof setInterval,
    clearIntervalFn: ((id: number) => {
      intervals.delete(id);
    }) as unknown as typeof clearInterval,
    /** Fire the single oldest pending debounce timeout. Returns true if fired. */
    fireNextTimeout(): boolean {
      const entry = timeouts.entries().next().value as [number, () => void] | undefined;
      if (!entry) return false;
      const [id, fn] = entry;
      timeouts.delete(id);
      fn();
      return true;
    },
    fireIntervals(): void {
      for (const fn of [...intervals.values()]) fn();
    },
    timeoutCount(): number {
      return timeouts.size;
    },
    intervalCount(): number {
      return intervals.size;
    },
  };
}

function createFakeWatch() {
  let handlers: WatchHandlers | null = null;
  let closed = false;
  return {
    watchDir: ((_dir: string, h: WatchHandlers) => {
      handlers = h;
      return {
        close: () => {
          closed = true;
          handlers = null;
        },
      };
    }) as WatchDir,
    emitEvent: (eventType: string, filename: string | null) =>
      handlers?.onEvent(eventType, filename),
    emitError: (error: unknown) => handlers?.onError(error),
    isActive: () => handlers !== null,
    wasClosed: () => closed,
  };
}

function createFakeFs(initial: Record<string, string>) {
  const files = new Map<string, string | null>(Object.entries(initial));
  return {
    readText: async (path: string): Promise<string | null> => files.get(path) ?? null,
    setFile: (path: string, content: string) => files.set(path, content),
    removeFile: (path: string) => files.set(path, null),
  };
}

interface Harness {
  deps: ThemeSyncDeps;
  timers: ReturnType<typeof createFakeTimers>;
  watch: ReturnType<typeof createFakeWatch>;
  fs: ReturnType<typeof createFakeFs>;
  applied: ThemeName[];
  logLines: string[];
  setThemeImpl: (t: ThemeName) => boolean;
  stateFile: string;
}

const STATE_FILE = "/state/theme";
const LOG_FILE = "/state/theme-sync.log";

function makeHarness(initialContent: string | null = "dark"): Harness {
  const timers = createFakeTimers();
  const watch = createFakeWatch();
  const fs = createFakeFs(
    initialContent === null ? {} : { [STATE_FILE]: initialContent },
  );
  const applied: ThemeName[] = [];
  const logLines: string[] = [];
  let setThemeResult = true;
  const setThemeImpl = (t: ThemeName) => {
    if (setThemeResult) applied.push(t);
    return setThemeResult;
  };
  const deps: ThemeSyncDeps = {
    stateFile: STATE_FILE,
    logFile: LOG_FILE,
    readText: fs.readText,
    appendLine: async (_path, line) => {
      logLines.push(line);
    },
    watchDir: watch.watchDir,
    setTheme: setThemeImpl,
    now: () => FIXED_DATE,
    setTimeoutFn: timers.setTimeoutFn,
    clearTimeoutFn: timers.clearTimeoutFn,
    setIntervalFn: timers.setIntervalFn,
    clearIntervalFn: timers.clearIntervalFn,
    debounceMs: 120,
    pollIntervalMs: 1500,
  };
  return { deps, timers, watch, fs, applied, logLines, setThemeImpl, stateFile: STATE_FILE };
}

/** Flush pending microtasks (debounce/poll callbacks are fire-and-forget async). */
const flush = () => new Promise<void>((resolve) => setTimeout(resolve, 0));

// ── parseTheme ──────────────────────────────────────────────────────────────

describe("parseTheme", () => {
  test("accepts dark and light", () => {
    expect(parseTheme("dark")).toBe("dark");
    expect(parseTheme("light")).toBe("light");
  });

  test("is case- and whitespace-insensitive", () => {
    expect(parseTheme("  DARK\n")).toBe("dark");
    expect(parseTheme("Light")).toBe("light");
  });

  test("rejects garbage, empty, and missing input", () => {
    expect(parseTheme("blue")).toBeNull();
    expect(parseTheme("")).toBeNull();
    expect(parseTheme("   ")).toBeNull();
    expect(parseTheme(null)).toBeNull();
    expect(parseTheme(undefined)).toBeNull();
  });
});

// ── resolveStatePaths ───────────────────────────────────────────────────────

describe("resolveStatePaths", () => {
  test("uses XDG_STATE_HOME when set", () => {
    const p = resolveStatePaths("/home/u", { XDG_STATE_HOME: "/xdg/state" });
    expect(p.stateDir).toBe("/xdg/state");
    expect(p.stateFile).toBe("/xdg/state/theme");
    expect(p.logFile).toBe("/xdg/state/theme-sync.log");
  });

  test("falls back to ~/.local/state when unset or blank", () => {
    expect(resolveStatePaths("/home/u", {}).stateDir).toBe("/home/u/.local/state");
    expect(resolveStatePaths("/home/u", { XDG_STATE_HOME: "" }).stateDir).toBe(
      "/home/u/.local/state",
    );
    expect(resolveStatePaths("/home/u", { XDG_STATE_HOME: "   " }).stateDir).toBe(
      "/home/u/.local/state",
    );
  });
});

// ── createThemeSync ─────────────────────────────────────────────────────────

describe("createThemeSync", () => {
  test("applies and logs the current theme on start", async () => {
    const h = makeHarness("light");
    const c = createThemeSync(h.deps);
    await c.start();

    expect(h.applied).toEqual(["light"]);
    expect(h.logLines).toEqual([`${FIXED_DATE.toISOString()} (none) -> light`]);
    expect(c.appliedTheme).toBe("light");
    expect(c.isWatching()).toBe(true);
    expect(c.isPolling()).toBe(false);
    c.stop();
  });

  test("applies on a change event only when the value differs", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    h.fs.setFile(h.stateFile, "light");
    h.watch.emitEvent("change", "theme");
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();

    expect(h.applied).toEqual(["dark", "light"]);
    expect(h.logLines).toEqual([
      `${FIXED_DATE.toISOString()} (none) -> dark`,
      `${FIXED_DATE.toISOString()} dark -> light`,
    ]);

    // Same value again → nothing new.
    h.watch.emitEvent("change", "theme");
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();
    expect(h.applied).toEqual(["dark", "light"]);
    expect(h.logLines).toHaveLength(2);
    c.stop();
  });

  test("debounces atomic-write event bursts into a single sync", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    h.fs.setFile(h.stateFile, "light");
    h.watch.emitEvent("rename", "theme"); // atomic replace
    h.watch.emitEvent("change", "theme"); // second event in the burst
    expect(h.timers.timeoutCount()).toBe(1); // coalesced

    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();
    expect(h.applied).toEqual(["dark", "light"]);
    c.stop();
  });

  test("survives atomic-write replacement via rename event", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    h.fs.setFile(h.stateFile, "light");
    h.watch.emitEvent("rename", "theme");
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();
    expect(h.applied).toEqual(["dark", "light"]);
    c.stop();
  });

  test("handles null filename from the watcher", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    h.fs.setFile(h.stateFile, "light");
    h.watch.emitEvent("rename", null);
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();
    expect(h.applied).toEqual(["dark", "light"]);
    c.stop();
  });

  test("any directory event triggers a no-op sync when content is unchanged", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    // Unrelated file churn in the same state dir → debounced sync → re-read
    // of the state file finds the same value → no apply, no log.
    h.watch.emitEvent("change", "other.txt");
    expect(h.timers.timeoutCount()).toBe(1);
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();
    expect(h.applied).toEqual(["dark"]);
    expect(h.logLines).toHaveLength(1);
    expect(c.appliedTheme).toBe("dark");
    c.stop();
  });

  test("garbage content is a no-op (no crash, no apply)", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    h.fs.setFile(h.stateFile, "blue\n");
    h.watch.emitEvent("change", "theme");
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();

    h.fs.setFile(h.stateFile, "");
    h.watch.emitEvent("change", "theme");
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();

    expect(h.applied).toEqual(["dark"]);
    expect(h.logLines).toHaveLength(1);
    expect(c.appliedTheme).toBe("dark");
    c.stop();
  });

  test("missing file is a no-op (no crash)", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    h.fs.removeFile(h.stateFile);
    h.watch.emitEvent("change", "theme");
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();
    expect(h.applied).toEqual(["dark"]);
    c.stop();
  });

  test("falls back to polling when the watcher errors", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();
    expect(c.isWatching()).toBe(true);

    h.watch.emitError(new Error("inotify exploded"));
    expect(c.isWatching()).toBe(false);
    expect(c.isPolling()).toBe(true);
    expect(h.watch.wasClosed()).toBe(true);

    h.fs.setFile(h.stateFile, "light");
    h.timers.fireIntervals();
    await flush();
    expect(h.applied).toEqual(["dark", "light"]);
    expect(h.logLines).toHaveLength(2);
    c.stop();
  });

  test("falls back to polling when fs.watch is unavailable", async () => {
    const h = makeHarness("dark");
    const deps: ThemeSyncDeps = {
      ...h.deps,
      watchDir: () => null, // unavailable
    };
    const c = createThemeSync(deps);
    await c.start();

    expect(c.isWatching()).toBe(false);
    expect(c.isPolling()).toBe(true);

    h.fs.setFile(h.stateFile, "light");
    h.timers.fireIntervals();
    await flush();
    expect(h.applied).toEqual(["dark", "light"]);
    c.stop();
  });

  test("a rejected setTheme is not applied or logged; a later success is", async () => {
    const h = makeHarness("dark");
    // First apply (initial sync) is rejected → nothing applied.
    let reject = true;
    const deps: ThemeSyncDeps = {
      ...h.deps,
      setTheme: (t) => {
        if (reject) return false;
        h.applied.push(t);
        return true;
      },
    };
    const c = createThemeSync(deps);
    await c.start();
    expect(h.applied).toEqual([]);
    expect(h.logLines).toEqual([]);
    expect(c.appliedTheme).toBeNull();

    // Now setTheme succeeds for a real switch.
    reject = false;
    h.fs.setFile(h.stateFile, "light");
    h.watch.emitEvent("change", "theme");
    expect(h.timers.fireNextTimeout()).toBe(true);
    await flush();
    expect(h.applied).toEqual(["light"]);
    expect(h.logLines).toEqual([`${FIXED_DATE.toISOString()} (none) -> light`]);
    c.stop();
  });

  test("stop() cleans up watcher, timers, and pending work", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();

    h.fs.setFile(h.stateFile, "light");
    h.watch.emitEvent("change", "theme");
    expect(h.timers.timeoutCount()).toBe(1);

    c.stop();
    expect(c.isWatching()).toBe(false);
    expect(h.timers.timeoutCount()).toBe(0);
    expect(h.timers.intervalCount()).toBe(0);

    // Nothing fires after stop.
    h.watch.emitEvent("change", "theme");
    h.timers.fireIntervals();
    await flush();
    expect(h.applied).toEqual(["dark"]);
  });

  test("can restart after stop and picks up new state", async () => {
    const h = makeHarness("dark");
    const c = createThemeSync(h.deps);
    await c.start();
    expect(h.applied).toEqual(["dark"]);

    c.stop();
    h.fs.setFile(h.stateFile, "light");
    await c.start();

    expect(c.appliedTheme).toBe("light");
    expect(h.applied).toEqual(["dark", "light"]);
    expect(h.logLines).toEqual([
      `${FIXED_DATE.toISOString()} (none) -> dark`,
      `${FIXED_DATE.toISOString()} dark -> light`,
    ]);
    c.stop();
  });
});
