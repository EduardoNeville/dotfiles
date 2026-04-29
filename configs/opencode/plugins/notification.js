/**
 * OpenCode Notification Plugin
 *
 * Sends desktop notifications on session lifecycle events.
 *
 * ## Propagation Chain
 *
 *   opencode plugin
 *     │
 *     ├─ SSH session? (SSH_TTY set)
 *     │   └─ Write raw OSC 9 directly to SSH_TTY (/dev/pts/N)
 *     │      Bypasses tmux entirely → SSH → WezTerm → notify-send → desktop
 *     │
 *     └─ No SSH (local)
 *         ├─ Inside tmux? (TMUX set)
 *         │   └─ Wrap in tmux DCS passthrough: \ePtmux;\e<OSC>\e\\
 *         │      tmux forwards inner OSC 9 to the outer terminal (WezTerm)
 *         │
 *         └─ Direct terminal
 *             └─ Raw OSC 9 to stderr → WezTerm interprets directly
 *
 * ## Why the tmux DCS wrapper?
 *
 * tmux's `allow-passthrough on` does NOT blindly forward all escape sequences.
 * It enables a specific protocol: programs must wrap sequences in a DCS string
 * (\ePtmux;\e ... \e\\) for tmux to forward them to the outer terminal.
 * This is the same mechanism used for OSC 52 clipboard passthrough.
 *
 * ## Platform Support
 *
 *   - macOS:        Native osascript notifications
 *   - Linux/remote: OSC 9 terminal escape sequences
 *
 * ## Event Types
 *
 *   - session.idle      → Agent finished responding, waiting for input
 *   - session.error     → Session encountered an error
 *   - session.compacted → Context window trimmed (compaction occurred)
 */

export const NotificationPlugin = async ({ project, client, $ }) => {
  /**
   * Build and emit an OSC 9 notification escape sequence.
   *
   * Selects the correct output path and encoding based on the environment:
   * - Direct SSH pty write when available (most reliable, bypasses tmux)
   * - Tmux DCS-wrapped passthrough when inside tmux without SSH
   * - Raw OSC 9 when in a direct terminal
   *
   * The escape sequence format is: ESC ] 9 ; <content> BEL
   *
   * @param {string} title   - Notification title
   * @param {string} message - Notification body
   */
  async function emitOsc9(title, message) {
    const rawSeq = `\x1b]9;${title}: ${message}\x07`
    const tmuxWrappedSeq = `\x1bPtmux;\x1b${rawSeq}\x1b\\`

    const isTmux = !!process.env.TMUX
    const sshTty = process.env.SSH_TTY

    //
    // Path 1: SSH session — write raw OSC 9 directly to the SSH pty.
    // This bypasses tmux entirely, going straight to WezTerm.
    // No DCS wrapper needed since tmux never sees the sequence.
    //
    if (sshTty) {
      try {
        await $`printf "%s" ${rawSeq} > ${sshTty}`.quiet()
        return
      } catch {
        // SSH_TTY may not be writable (permissions, or closed)
      }
    }

    //
    // Path 2: Inside tmux but no SSH — use the tmux DCS passthrough wrapper.
    // tmux recognizes \ePtmux;\e...\e\\ and forwards the inner sequence
    // to the outer terminal (WezTerm).
    //
    const seq = isTmux ? tmuxWrappedSeq : rawSeq

    // Write to stderr first (least likely to be captured by the TUI renderer)
    try {
      process.stderr.write(seq)
      return
    } catch {
      // stderr may be redirected or unavailable
    }

    // Final fallback: stdout
    try {
      process.stdout.write(seq)
    } catch {
      // Completely silent failure — notifications are non-critical
    }
  }

  /**
   * macOS path: use native osascript notifications.
   */
  async function emitOsascript(title, message) {
    try {
      await $`osascript -e 'display notification ${message} with title ${title}'`.quiet()
    } catch {
      // Silently ignore
    }
  }

  async function notify(title, message) {
    if (process.platform === "darwin") {
      await emitOsascript(title, message)
    } else {
      await emitOsc9(title, message)
    }
  }

  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.idle":
          await notify("opencode", "Session completed — agent is now idle.")
          break

        case "session.error":
          await notify(
            "opencode — Error",
            "Session encountered an error. Check the session for details."
          )
          break

        case "session.compacted":
          await notify(
            "opencode",
            "Session compacted — context window was trimmed to save space."
          )
          break
      }
    },
  }
}
