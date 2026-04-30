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
 *   - session.idle       → Agent finished responding. Includes session title
 *                           and file change summary (+additions -deletions).
 *   - session.error      → Session encountered an error. Includes the
 *                           specific error type and message (e.g. APIError).
 *   - session.compacted  → Context window trimmed. Includes session title.
 *   - permission.updated → Agent needs approval for an action. Includes
 *                           the permission type (bash, edit, read, etc.)
 *                           and the human-readable title.
 *
 * ## Session Metadata
 *
 *   Session titles are cached from session.created / session.updated
 *   events to avoid extra API calls. On cache miss, falls back to
 *   client.session.get() for the title and file change summary.
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

  // ── Session metadata cache ────────────────────────────────────
  // session.created and session.updated events carry the full
  // Session object (including title). We cache titles here so
  // session.idle and session.compacted (which only carry sessionID)
  // can display them without making an API call.
  const sessionCache = {}

  /**
   * Get the session title, cache-first.
   * Falls back to client.session.get() on cache miss.
   */
  async function getSessionTitle(sessionID) {
    if (sessionCache[sessionID]) return sessionCache[sessionID]
    try {
      const session = await client.session.get({ path: { id: sessionID } })
      const title = session?.title?.trim()
      if (title) {
        sessionCache[sessionID] = title
        return title
      }
    } catch {
      // Session may have been deleted, or client unavailable
    }
    return null
  }

  /**
   * Fetch file change summary for the session.
   * Returns a formatted string like "3 files (+42 -8)" or null.
   */
  async function getChangeSummary(sessionID) {
    try {
      const session = await client.session.get({ path: { id: sessionID } })
      if (session?.summary) {
        const { additions = 0, deletions = 0, files = 0 } = session.summary
        if (files > 0) {
          return `${files} file${files !== 1 ? "s" : ""} (+${additions} -${deletions})`
        }
      }
    } catch {
      // Silently skip — summary is non-critical
    }
    return null
  }

  /**
   * Format a typed error object into a human-readable string.
   */
  function formatError(error) {
    if (!error) return "Unknown error"
    const name = error.name || "Error"
    const message = error.data?.message || ""
    const status = error.data?.statusCode ? ` [${error.data.statusCode}]` : ""
    const retry = error.data?.isRetryable ? " (retryable)" : ""
    return `${name}: ${message}${status}${retry}`.trim()
  }

  // ═══════════════════════════════════════════════════════════════
  // Event handler
  // ═══════════════════════════════════════════════════════════════

  return {
    event: async ({ event }) => {
      switch (event.type) {
        // ── Cache session titles from lifecycle events ──────────
        case "session.created":
        case "session.updated": {
          const info = event.properties?.info
          if (info?.id && info?.title) {
            sessionCache[info.id] = info.title
          }
          break
        }

        // ── Session completed / agent idle ─────────────────────
        case "session.idle": {
          const sid = event.properties.sessionID
          const title = await getSessionTitle(sid)
          const changes = await getChangeSummary(sid)

          let msg = title ? `"${title}" — ` : ""
          msg += "agent is now idle."
          if (changes) msg += ` ${changes}.`

          await notify("opencode", msg)
          break
        }

        // ── Session error ──────────────────────────────────────
        case "session.error": {
          const errorMsg = formatError(event.properties.error)
          await notify("opencode — Error", errorMsg)
          break
        }

        // ── Session compacted ──────────────────────────────────
        case "session.compacted": {
          const sid = event.properties.sessionID
          const title = await getSessionTitle(sid)
          const msg = title
            ? `"${title}" — session compacted.`
            : "Session compacted — context trimmed."

          await notify("opencode", msg)
          break
        }

        // ── Permission / approval request ──────────────────────
        case "permission.updated": {
          const perm = event.properties
          const kind = perm?.type || "permission"
          const desc = perm?.title || "approval needed"
          await notify("opencode — Needs Approval", `${kind} — ${desc}`)
          break
        }
      }
    },
  }
}
