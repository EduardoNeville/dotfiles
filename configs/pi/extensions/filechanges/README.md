# filechanges (pi extension)

Tracks files changed (modified/created) by **pi** via the built-in `edit` and `write` tools.

## Features

- Persistent log (stored in session as custom entries)
- Status line + widget listing changed files
- `/filechanges` overlay to inspect diffs
- **Per-file accept/decline**: press `a` to accept or `d` to decline a single file in the diff overlay
- `/filechanges-accept` to clear the log (keep files)
- `/filechanges-decline` to revert logged changes (restore original contents / delete created files)
- **Binary-file safety**: binary files are automatically detected and skipped
- **External-modification guard**: warns before reverting files that changed outside pi

## Usage

1. Reload pi: `/reload`
2. Make changes through pi (using `edit`/`write`)
3. Run:
   - `/filechanges` to inspect
   - In the diff overlay: `a` = accept this file, `d` = decline this file, `esc` = go back
   - `/filechanges-accept` to accept all (clear log)
   - `/filechanges-decline` to decline all (revert)

### Non-interactive usage

If `ctx.hasUI` is false (print/json mode):

- `/filechanges` — print summary of changed files
- `/filechanges --accept-force` — accept all changes without confirmation
- `/filechanges --decline-force` — decline all changes without confirmation
- `/filechanges-accept --accept-force` — accept all headlessly
- `/filechanges-decline --decline-force` — decline all headlessly

### Inspecting another directory (`--cwd`) and machine-readable output (`--json`)

Used by the pi-marshals Commander to inspect Marshal worktrees without touching the current session's state (read-only — never mutates the in-memory log):

- `/filechanges --cwd <path>` — replay the change log against `<path>` (relative paths resolve against the session cwd) and print a plain-text listing of what pi changed there
- `/filechanges --json` — dump the current session's tracked changes as JSON
- `/filechanges --cwd <path> --json` — JSON report for another directory, e.g. a Marshal worktree:

```json
{
  "cwd": "/tmp/pi-marshals/abc123-marshal-davout",
  "summary": { "total": 2, "edited": 1, "created": 1 },
  "tracked": [
    {
      "path": "src/auth.ts",
      "absPath": "/tmp/pi-marshals/abc123-marshal-davout/src/auth.ts",
      "kind": "edited",
      "originalContent": "...",
      "currentContent": "...",
      "added": 3,
      "removed": 1,
      "diff": "--- ...\n+++ ...\n@@ ...\n",
      "updatedAt": 1754060000000
    }
  ]
}
```

**Constraint:** the paths stored in the session log are relative to the cwd they were recorded in. `--cwd` must therefore point at the exact directory the work was performed in (for Marshals: their worktree) — passing a different base silently re-resolves the paths elsewhere.

## Notes

- Only tracks changes performed through `edit` and `write` tools.
- Original file contents are stored as SHA-256 hashes. For git-tracked repos,
  the original is recovered via `git show HEAD:<path>`. For non-git repos,
  content is cached in `.pi/filechanges/baselines/`.
- Created files that are later deleted stay tracked (showing the removal) until
  explicitly accepted or declined.
- If a file is modified outside pi between tracking and decline, the extension
  warns before overwriting. In `--decline-force` mode, externally-modified files
  are skipped with a warning.
