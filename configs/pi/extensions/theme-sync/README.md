# pi-theme-sync

Keeps the pi TUI theme in sync with a shared theme state file so that external
tools (a desktop environment helper, another shell, etc.) can flip pi's theme
by writing one token.

- **State file:** `$XDG_STATE_HOME/theme`, else `~/.local/state/theme` — a
  single token: `dark` or `light` (case/whitespace insensitive).
- **On `session_start`:** reads the state file and applies the theme.
- **Watching:** `fs.watch` (inotify) on the state file's **parent directory**
  so atomic-write replacement (`mv tmp theme`) is caught; falls back to
  polling every 1.5s when `fs.watch` is unavailable or errors. Events are
  debounced (120ms) to coalesce atomic-write bursts.
- **Apply rules:** parses `dark|light`; calls `ctx.ui.setTheme` **only when the
  parsed value differs** from the last applied theme. Missing/garbage content
  is ignored (never crashes).
- **Verification log:** one line per applied switch appended to
  `<state-dir>/theme-sync.log`:

  ```
  2026-01-02T03:04:05.678Z (none) -> dark
  2026-01-02T03:04:05.789Z dark -> light
  ```

- **Cleanup:** watcher and timers are stopped on `session_shutdown`.

## settings.json safety

The runtime `ctx.ui.setTheme(name)` with a **string** name persists the theme
into settings.json. This extension deliberately passes the **Theme object**
(`ctx.ui.getTheme(name)` → `ctx.ui.setTheme(themeObject)`) instead, which
applies in-memory only — the configured `settings.json` `theme` field is never
rewritten by the extension.

## Development

The core (`sync.ts`) is pi-runtime-free and dependency-injected so it can be
tested standalone:

```bash
bun test          # unit tests (fakes) + real-fs integration tests
```

The extension entry point (`index.ts`) only wires node built-ins
(`node:fs`, `node:path`, `node:os`) and the pi `ExtensionAPI` into that core.

## Files

- `index.ts` — pi extension entry (session_start / session_shutdown wiring)
- `sync.ts` — testable core: `parseTheme`, `resolveStatePaths`, `createThemeSync`
- `sync.test.ts` — deterministic unit tests with faked fs/watch/timers
- `integration.test.ts` — real-fs tests (flip, atomic replace, dedupe, garbage)
