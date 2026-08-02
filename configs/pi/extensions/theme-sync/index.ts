/**
 * pi-theme-sync — keep the pi TUI theme in sync with a shared theme state file.
 *
 * State file (XDG convention): $XDG_STATE_HOME/theme, else ~/.local/state/theme.
 * The file holds a single token: "dark" or "light".
 *
 * Behavior:
 *  - On session_start: read the state file and apply the theme.
 *  - Watch the state file via fs.watch (inotify) on the PARENT directory, which
 *    survives atomic-write replacement (`mv tmp theme`). If fs.watch is
 *    unavailable or errors, fall back to polling every 1.5s.
 *  - Apply the theme ONLY when it differs from the last applied value.
 *  - Append one line per applied switch to <state-dir>/theme-sync.log:
 *      <ISO timestamp> <old> -> <new>
 *  - Clean up the watcher/timers on session_shutdown.
 *
 * IMPORTANT (settings.json safety):
 *  Calling `ctx.ui.setTheme(name)` with a *string* makes pi persist the theme
 *  into settings.json (settingsManager.setTheme → save). To keep the runtime
 *  from rewriting settings.json we resolve the Theme object first
 *  (`ctx.ui.getTheme(name)`) and pass the object to `setTheme(themeObject)`,
 *  which applies it in-memory only (themeController.setThemeInstance).
 *
 * The sync/watch/log core lives in ./sync.ts and is unit-tested without the pi
 * runtime (bun test).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { appendFile, mkdir, readFile } from "node:fs/promises";
import { watch as fsWatch } from "node:fs";
import { dirname } from "node:path";
import { homedir } from "node:os";
import {
  createThemeSync,
  resolveStatePaths,
  type ThemeName,
  type ThemeSyncController,
} from "./sync.ts";

export default function (pi: ExtensionAPI) {
  const { stateDir, stateFile, logFile } = resolveStatePaths(homedir(), process.env);

  let controller: ThemeSyncController | null = null;

  pi.on("session_start", async (_event, ctx) => {
    // Session replacement / reload may fire session_start again on the same
    // instance — restart idempotently instead of stacking watchers.
    controller?.stop();
    controller = null;

    // Apply via the Theme OBJECT path so pi never rewrites settings.json.
    const setTheme = (theme: ThemeName): boolean => {
      if (!ctx?.hasUI) return false;
      try {
        const themeObject = ctx.ui.getTheme(theme);
        if (!themeObject) return false;
        const result = ctx.ui.setTheme(themeObject);
        return !!(result && result.success);
      } catch {
        return false;
      }
    };

    controller = createThemeSync({
      stateFile,
      logFile,
      readText: async (path) => {
        try {
          return await readFile(path, "utf-8");
        } catch {
          return null; // missing/unreadable → treated as "no state", no crash
        }
      },
      appendLine: async (path, line) => {
        await mkdir(dirname(path), { recursive: true });
        await appendFile(path, `${line}\n`, "utf-8");
      },
      watchDir: (dir, handlers) => {
        try {
          const watcher = fsWatch(
            dir,
            { persistent: true, encoding: "utf8" },
            (eventType, filename) => {
              handlers.onEvent(eventType ?? "", filename ?? null);
            },
          );
          watcher.on("error", (error) => handlers.onError(error));
          return { close: () => watcher.close() };
        } catch {
          return null; // fs.watch unavailable → polling fallback
        }
      },
      setTheme,
      onError: (error, context) => {
        console.warn(`[theme-sync] ${context}:`, error);
      },
    });

    await controller.start();
  });

  pi.on("session_shutdown", () => {
    controller?.stop();
    controller = null;
  });
}
