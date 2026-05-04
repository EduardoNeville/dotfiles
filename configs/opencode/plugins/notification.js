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
 *   - permission.ask     → Agent needs approval for an action. Includes
 *                           the permission type (bash, edit, read, etc.)
 *                           and the human-readable title.
 *
 * ## Session Metadata
 *
 *   Session titles are cached from session.created / session.updated
 *   events to avoid extra API calls. On cache miss, a single
 *   client.session.get() call fetches agent type, title, and change
 *   summary together (consolidated via getSessionInfo()).
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
    const rawSeq = `\x1b]9;${title}: ${message}\x07`;
    const tmuxWrappedSeq = `\x1bPtmux;\x1b${rawSeq}\x1b\\`;

    const isTmux = !!process.env.TMUX;
    const sshTty = process.env.SSH_TTY;

    //
    // Path 1: SSH session — write raw OSC 9 directly to the SSH pty.
    // This bypasses tmux entirely, going straight to WezTerm.
    // No DCS wrapper needed since tmux never sees the sequence.
    //
    if (sshTty) {
      try {
        await $`printf "%s" ${rawSeq} > ${sshTty}`.quiet();
        return;
      } catch {
        // SSH_TTY may not be writable (permissions, or closed)
      }
    }

    //
    // Path 2: Inside tmux but no SSH — use the tmux DCS passthrough wrapper.
    // tmux recognizes \ePtmux;\e...\e\\ and forwards the inner sequence
    // to the outer terminal (WezTerm).
    //
    const seq = isTmux ? tmuxWrappedSeq : rawSeq;

    // Write to stderr first (least likely to be captured by the TUI renderer)
    try {
      process.stderr.write(seq);
      return;
    } catch {
      // stderr may be redirected or unavailable
    }

    // Final fallback: stdout
    try {
      process.stdout.write(seq);
    } catch {
      // Completely silent failure — notifications are non-critical
    }
  }

  /**
   * macOS path: use native osascript notifications.
   */
  async function emitOsascript(title, message) {
    try {
      await $`osascript -e 'display notification ${message} with title ${title}'`.quiet();
    } catch {
      // Silently ignore
    }
  }

  async function notify(title, message) {
    if (process.platform === "darwin") {
      await emitOsascript(title, message);
    } else {
      await emitOsc9(title, message);
    }
  }

  // ── Debug helper (enabled with OPCODE_NOTIFY_DEBUG=1) ──────
  const debug = process.env.OPCODE_NOTIFY_DEBUG === "1"
    ? (...args) => console.error("[notify]", ...args)
    : () => {};

  // ── Session metadata cache ────────────────────────────────────
  // session.created and session.updated events carry the full
  // Session object (including title). We cache titles here so
  // session.idle and session.compacted (which only carry sessionID)
  // can display them without making an API call.
  const sessionCache = {};

  /**
   * Fetch session metadata (agent type, title, change summary) in a single API call.
   * Cache-first for titles — avoids redundant API calls.
   * Returns { agentType, title, changes }.
   */
  async function getSessionInfo(sessionID) {
    if (!sessionID) {
      debug("getSessionInfo called with no sessionID");
      return { agentType: "agent", title: null, changes: null };
    }

    try {
      const session = await client.session.get({ path: { id: sessionID } });
      if (!session) {
        return { agentType: "agent", title: sessionCache[sessionID] || null, changes: null };
      }

      // Cache title for future use (from session.created / session.updated events)
      const title = session.title?.trim() || null;
      if (title) sessionCache[sessionID] = title;

      // Determine agent type
      const isSubagent = session?.isSubagent || session?.agentType === "subagent" || session?.parentSessionId;
      const agentType = isSubagent ? "subagent" : "agent";

      // Build change summary from session stats
      let changes = null;
      if (session?.summary?.files > 0) {
        const { additions = 0, deletions = 0, files = 0 } = session.summary;
        changes = `${files} file${files !== 1 ? "s" : ""} (+${additions} -${deletions})`;
      }

      return { agentType, title, changes };
    } catch (err) {
      debug("getSessionInfo error:", err);
      return { agentType: "agent", title: sessionCache[sessionID] || null, changes: null };
    }
  }

  /**
   * Format a typed error object into a human-readable string.
   */
  function formatError(error) {
    if (!error) return "Unknown error";
    const name = error.name || "Error";
    const message = error.data?.message || "";
    const status = error.data?.statusCode ? ` [${error.data.statusCode}]` : "";
    const retry = error.data?.isRetryable ? " (retryable)" : "";
    return `${name}: ${message}${status}${retry}`.trim();
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
          const info = event.properties?.info;
          if (info?.id && info?.title) {
            sessionCache[info.id] = info.title;
          }
          break;
        }

// ── Session completed / agent idle ─────────────────────
        case "session.idle": {
          const sid = event.properties?.sessionID ?? event.properties?.id ?? event.properties?.info?.id ?? event.id;
          const { agentType, title, changes } = await getSessionInfo(sid);
          let msg = title ? `"${title}" — ` : "";
          msg += "is now idle.";
          if (changes) msg += ` ${changes}.`;
          debug("session.idle notification:", { agentType, title, changes });
          await notify(`opencode - ${agentType}`, msg);
          break;
        }

        // ── Session error ──────────────────────────────────────
        case "session.error": {
          const sid = event.properties?.sessionID ?? event.properties?.id ?? event.properties?.info?.id ?? event.id;
          const { agentType } = await getSessionInfo(sid);
          const errorMsg = formatError(event.properties.error);
          debug("session.error notification:", { agentType, error: errorMsg });
          await notify(`opencode - ${agentType}`, errorMsg);
          break;
        }

// ── Session compacted ──────────────────────────────────
        case "session.compacted": {
          const sid = event.properties?.sessionID ?? event.properties?.id ?? event.properties?.info?.id ?? event.id;
          const { agentType, title } = await getSessionInfo(sid);
          const msg = title
            ? `"${title}" — session compacted.`
            : "Session compacted — context trimmed.";
          debug("session.compacted notification:", { agentType, title });
          await notify(`opencode - ${agentType}`, msg);
          break;
        }

      }
    },

    // ── Permission / approval request ────────────────────────
    "permission.ask": async (input) => {
      const kind = input?.type || "permission";
      const desc = input?.title || "approval needed";
      debug("permission.ask notification:", { kind, desc });
      await notify("opencode - agent", `${kind} — ${desc}`);
    },

    // ── Agent message received ─────────────────────────────
    "chat.message": async ({ sessionID, agent }) => {
      const { agentType, title } = await getSessionInfo(sessionID);
      const sessionTitle = title ? `"${title}"` : "Session";
      debug("chat.message notification:", { agentType, title, agent });
      await notify(`opencode - ${agentType}`, `${sessionTitle} — waiting for your input.`);
    },
  };
};
