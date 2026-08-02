/**
 * theme-sync core — pure, pi-runtime-free logic.
 *
 * Keeps a "current theme" in sync with a shared state file (default:
 * $XDG_STATE_HOME/theme or ~/.local/state/theme). It is fully dependency
 * injected (file IO, watcher, timers, theme setter) so it can be unit-tested
 * with `bun test` without loading the pi runtime.
 *
 * Strategy:
 *  - Watch the PARENT directory (robust to atomic-write replacement: a
 *    `mv tmp theme` shows up as events on the directory, and the directory
 *    inode itself never changes).
 *  - Sync on ANY directory event. Bun (and inotify in general) can coalesce
 *    or misattribute rename events during rapid atomic writes (a `mv tmp
 *    theme` burst may surface as a single `rename` event for the *old* tmp
 *    name). Filtering by basename is therefore fragile; instead every event
 *    triggers a debounced re-read of the state file. The dedupe (apply only
 *    when different) makes these extra reads harmless.
 *  - If fs.watch is unavailable, throws at setup, or errors at runtime,
 *    fall back to polling every `pollIntervalMs` (default 1.5s).
 *  - All events are debounced so an atomic write's event burst (rename +
 *    change, or a double-fire) is coalesced into a single sync.
 *  - A theme is applied ONLY when it differs from the last successfully
 *    applied theme; each applied switch appends one log line
 *    "<ISO-timestamp> <old> -> <new>" to the log file.
 */

import { dirname, join } from "node:path";

export type ThemeName = "dark" | "light";

/** Parse a raw state-file value into a valid theme, or null for missing/garbage. */
export function parseTheme(raw: string | null | undefined): ThemeName | null {
  if (raw === null || raw === undefined) return null;
  const value = raw.trim().toLowerCase();
  if (value === "dark") return "dark";
  if (value === "light") return "light";
  return null;
}

export interface StatePaths {
  stateDir: string;
  stateFile: string;
  logFile: string;
}

/**
 * Resolve the shared theme state paths per the XDG convention:
 * `$XDG_STATE_HOME` if set and non-empty, else `<home>/.local/state`.
 */
export function resolveStatePaths(
  homeDir: string,
  env: { XDG_STATE_HOME?: string | undefined } = {},
  stateFileName = "theme",
  logFileName = "theme-sync.log",
): StatePaths {
  const xdg = env.XDG_STATE_HOME;
  const stateDir =
    typeof xdg === "string" && xdg.trim().length > 0
      ? xdg
      : join(homeDir, ".local", "state");
  return {
    stateDir,
    stateFile: join(stateDir, stateFileName),
    logFile: join(stateDir, logFileName),
  };
}

export interface WatchHandle {
  close(): void;
}

export interface WatchHandlers {
  onEvent: (eventType: string, filename: string | null) => void;
  onError: (error: unknown) => void;
}

/** Watch a directory. Return null to signal "unavailable — use polling". */
export type WatchDir = (
  dir: string,
  handlers: WatchHandlers,
) => WatchHandle | null;

export interface ThemeSyncDeps {
  stateFile: string;
  logFile: string;
  /** Read a file; return null when missing/unreadable. Must not throw. */
  readText: (path: string) => Promise<string | null>;
  /** Append one line (newline added by caller); may create parent dir. */
  appendLine: (path: string, line: string) => Promise<void>;
  /** Watch the state file's parent directory; return null → polling fallback. */
  watchDir: WatchDir;
  /** Apply a theme. Return true when the theme was actually applied. */
  setTheme: (theme: ThemeName) => boolean;
  now?: () => Date;
  setTimeoutFn?: typeof setTimeout;
  clearTimeoutFn?: typeof clearTimeout;
  setIntervalFn?: typeof setInterval;
  clearIntervalFn?: typeof clearInterval;
  /** Polling fallback interval in ms (default 1500). */
  pollIntervalMs?: number;
  /** Debounce for coalescing atomic-write event bursts in ms (default 120). */
  debounceMs?: number;
  onError?: (error: unknown, context: string) => void;
}

export interface ThemeSyncController {
  /** Initial sync, then start watching (falling back to polling). Idempotent. */
  start(): Promise<void>;
  /** Close the watcher and clear all timers. Idempotent. */
  stop(): void;
  /** Read + parse + apply + log if different. Returns true when a switch happened. */
  syncNow(): Promise<boolean>;
  /** Last successfully applied theme (null before the first successful apply). */
  readonly appliedTheme: ThemeName | null;
  /** True when the controller currently uses the polling fallback. */
  isPolling(): boolean;
  /** True when a directory watcher is currently active. */
  isWatching(): boolean;
}

export function createThemeSync(deps: ThemeSyncDeps): ThemeSyncController {
  const stateDir = dirname(deps.stateFile);

  const now = deps.now ?? (() => new Date());
  const pollIntervalMs = deps.pollIntervalMs ?? 1500;
  const debounceMs = deps.debounceMs ?? 120;
  const setT = deps.setTimeoutFn ?? setTimeout;
  const clearT = deps.clearTimeoutFn ?? clearTimeout;
  const setI = deps.setIntervalFn ?? setInterval;
  const clearI = deps.clearIntervalFn ?? clearInterval;

  let appliedTheme: ThemeName | null = null;
  let watcher: WatchHandle | null = null;
  let pollTimer: ReturnType<typeof setInterval> | null = null;
  let debounceTimer: ReturnType<typeof setTimeout> | null = null;
  let stopped = true;

  function fail(error: unknown, context: string): void {
    try {
      deps.onError?.(error, context);
    } catch {
      // error reporting must never crash the sync loop
    }
  }

  /**
   * Read + parse the state file, apply the theme when it differs, and log
   * each applied switch. Missing/garbage content is a no-op (no crash).
   */
  async function syncNow(): Promise<boolean> {
    if (stopped) return false;
    let raw: string | null = null;
    try {
      raw = await deps.readText(deps.stateFile);
    } catch (error) {
      fail(error, "read-state");
      return false;
    }
    const theme = parseTheme(raw);
    if (theme === null) return false; // missing / garbage → keep current theme
    if (theme === appliedTheme) return false; // only apply when different

    let applied = false;
    try {
      applied = deps.setTheme(theme);
    } catch (error) {
      fail(error, "set-theme");
      return false;
    }
    if (!applied) return false;

    const old = appliedTheme === null ? "(none)" : appliedTheme;
    appliedTheme = theme;
    try {
      await deps.appendLine(deps.logFile, `${now().toISOString()} ${old} -> ${theme}`);
    } catch (error) {
      fail(error, "append-log");
    }
    return true;
  }

  function scheduleSync(): void {
    if (stopped) return;
    if (debounceTimer !== null) clearT(debounceTimer);
    debounceTimer = setT(() => {
      debounceTimer = null;
      syncNow().catch((error) => fail(error, "sync"));
    }, debounceMs);
  }

  function startPolling(): void {
    if (stopped || pollTimer !== null) return;
    pollTimer = setI(() => {
      syncNow().catch((error) => fail(error, "poll"));
    }, pollIntervalMs);
  }

  function stopPolling(): void {
    if (pollTimer !== null) {
      clearI(pollTimer);
      pollTimer = null;
    }
  }

  function startWatch(): void {
    if (stopped || watcher !== null) return;
    let handle: WatchHandle | null = null;
    try {
      handle = deps.watchDir(stateDir, {
        // Deliberately ignore eventType/filename: bun can report a rapid
        // atomic replace as a single `rename` for the old tmp name, so the
        // basename check would miss it. Any directory event may mean the
        // state file changed; syncNow() re-reads it and no-ops when the
        // parsed value is unchanged.
        onEvent: () => {
          if (stopped) return;
          scheduleSync();
        },
        onError: (error) => {
          fail(error, "watch");
          if (handle) {
            try {
              handle.close();
            } catch {
              // ignore close errors
            }
            handle = null;
          }
          watcher = null;
          // Fall back to polling when the watcher dies.
          startPolling();
        },
      });
    } catch (error) {
      fail(error, "watch-start");
      handle = null;
    }
    if (handle !== null) {
      watcher = handle;
    } else {
      startPolling();
    }
  }

  async function start(): Promise<void> {
    stopped = false;
    await syncNow();
    if (stopped) return; // stop() may have raced the initial sync
    startWatch();
  }

  function stop(): void {
    stopped = true;
    if (debounceTimer !== null) {
      clearT(debounceTimer);
      debounceTimer = null;
    }
    stopPolling();
    if (watcher !== null) {
      try {
        watcher.close();
      } catch {
        // ignore close errors
      }
      watcher = null;
    }
  }

  return {
    start,
    stop,
    syncNow,
    get appliedTheme(): ThemeName | null {
      return appliedTheme;
    },
    isPolling: () => pollTimer !== null,
    isWatching: () => watcher !== null,
  };
}
