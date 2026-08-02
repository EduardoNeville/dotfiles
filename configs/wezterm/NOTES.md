# NOTES.md — wezterm OSC passthrough semantics (verified 2026-08-02)

Research for Marshal `wezterm-osc-verify`. Sources: wezterm.org docs
(fetched 2026-08-02) and wez/wezterm source on GitHub (`main`).

## 1. Does `window:emit('passthrough', text)` exist?

**No.** It does not exist and it errors at runtime.

* The Lua `Window` object documents its full method list at
  <https://wezterm.org/config/lua/window/index.html>: `active_key_table`,
  `active_pane`, `active_tab`, `active_workspace`, `composition_status`,
  `copy_to_clipboard`, `current_event`, `effective_config`, `focus`,
  `get_appearance`, `get_config_overrides`, `get_dimensions`,
  `get_selection_escapes_for_pane`, `get_selection_text_for_pane`,
  `is_focused`, `keyboard_modifiers`, `leader_is_active`, `maximize`,
  `mux_window`, `perform_action`, `restore`, `set_config_overrides`,
  `set_inner_size`, `set_left_status`, `set_position`, `set_right_status`,
  `toast_notification`, `toggle_fullscreen`, `window_id`.
  There is **no `emit` method** and no `passthrough`.
* Source confirmation: `wezterm-gui/src/scripting/guiwin.rs` (`GuiWin`
  userdata) registers exactly these methods — no `emit`.
* The Pane object has no `emit` either: `lua-api-crates/mux/src/pane.rs`
  (`send_paste`, `paste`, `send_text`, `inject_output`, ...).
* `emit` is a **module-level** function: `wezterm.emit(event_name, ...)`
  (<https://wezterm.org/config/lua/wezterm/emit.html>). It only resolves
  callbacks registered via `wezterm.on()` and calls them. WezTerm defines no
  `passthrough` event (see the `events: Window` list: bell, format-tab-title,
  format-window-title, open-uri, update-right-status, update-status,
  user-var-changed, window-config-reloaded, window-focus-changed,
  window-resized, augment-command-palette, new-tab-button-click).
* Consequence: `window:emit("theme-changed", ...)` / `window:emit("passthrough",
  ...)` raise `attempt to call a nil value (method 'emit')` inside the
  callback. wezterm catches callback errors and logs them
  (`log::error!("while processing {} event: {:#}", ...)` in
  `wezterm-gui/src/termwindow/mod.rs`), so the GUI survives, **but the rest
  of `toggle_theme()` is aborted** — including the
  `wezterm.run_child_process(...)` call that runs `propagate_state.sh`.
  In the old code the theme did switch (set_config_overrides ran first) but
  the tmux/remote propagation never ran.

## 2. Does wezterm answer OSC 10/11 QUERY sequences?

**Yes** (docs understate it).

* The escape-sequences doc (<https://wezterm.org/escape-sequences.html>)
  documents OSC 4 as "Change/Query Color Number" but lists OSC 10/11 only as
  "Set Default Text Foreground/Background Color", with no query mention.
* Source: `term/src/terminalstate/performer.rs` `osc_dispatch` →
  `ChangeDynamicColors` (OSC 10/11/12). For each `ColorOrQuery`:
  - `Query` → wezterm writes back `OSC 10/11; #<current-palette-color> ST`
    to the output stream (the `set_or_query!` macro).
  - `Color(c)` → wezterm sets `palette.foreground` / `palette.background`.
* History: OSC 110-119 reset + Neovim color-query support shipped in
  2020-05-17 (`docs/changelog.md`: "Change OSC rendering to use the long-form
  `ST` sequence `ESC \` ... recognized by Neovim when querying for color
  information."). So OSC 10/11 query support has existed for years.

Implication: programs that query colors get the right answer automatically
from wezterm's palette once `set_config_overrides` is applied — no OSC push
is needed. The OSC 10/11 *set* sequences the config emitted would only have
redundantly re-applied the same palette.

## 3. Is emitting a custom 'theme-changed' event harmless?

* `wezterm.emit("theme-changed", ...)`: yes — with no handler registered via
  `wezterm.on("theme-changed", ...)` it is a documented no-op that returns
  `true` (<https://wezterm.org/config/lua/wezterm/emit.html>).
* `window:emit("theme-changed", ...)`: **no** — it is the crash from §1.

## 4. Better documented mechanism

* `pane:send_text(text)`
  (<https://wezterm.org/config/lua/pane/send_text.html>, since
  20220624-141144-bd1b7c5d): "Sends text to the pane as-is." This writes to
  the pane's **input** stream (as if typed). It does **not** feed the
  terminal emulator's escape parser, so it would not update wezterm's palette.
* `pane:inject_output(text)`
  (<https://wezterm.org/config/lua/pane/inject_output.html>, since
  20221119-145034-49b9839f): "Sends text, which may include escape sequences,
  to the **output side** of the current pane. The text will be evaluated by
  the terminal emulator..." — this is the documented way to make wezterm
  process an OSC sequence such as `\x1b]11;#0000ff\x1b\\`.
  Caveat: "this works for local panes but not for multiplexer panes", so it
  would NOT help the original use-case of pushing colors through SSH/tmux.

## 5. Fix applied (configs/wezterm/wezterm.lua)

* `window:emit("theme-changed", ...)` → `wezterm.emit("theme-changed", ...)`
  (fixes the runtime crash; preserves the intended no-op event).
* Removed the non-functional `window:emit("passthrough", ...)` block (dead
  code) and replaced it with a comment explaining why, keeping the working
  `set_config_overrides` toggle and the `propagate_state.sh` call (which is
  now actually reachable again).
* `pane:inject_output` was deliberately NOT added: it is redundant with
  `set_config_overrides` and does not work on SSH/multiplexer panes — the
  case the old comment claimed to target. Cross-host sync remains the job of
  `propagate_state.sh`.
