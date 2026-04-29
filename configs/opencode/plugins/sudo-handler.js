/**
 * sudo-handler.js — OpenCode Server Plugin
 *
 * Intercepts sudo commands executed by the agent and injects a
 * SUDO_ASKPASS helper so sudo can authenticate without a TTY.
 *
 * ## How it works
 *
 *   tool.execute.before (bash + contains "sudo")
 *     │
 *     ├─ Password available? (via /tmp/opencode-sudo-pass or env var)
 *     │   └─ Yes → rewrite "sudo" to "sudo -A" (use askpass)
 *     │   └─ No  → leave command unchanged (sudo will error, agent adapts)
 *     │
 *   shell.env (every shell command)
 *     │
 *     └─ Set SUDO_ASKPASS=/tmp/opencode-askpass-<pid>.sh
 *        (helper script echoes password from temp file)
 *
 * ## Password sources (checked in order)
 *
 *   1. OPENCODE_SUDO_PASS environment variable
 *   2. /tmp/opencode-sudo-pass (written by sudo-prompt.tui.js)
 *
 * ## Security
 *
 *   - Password temp file: 0600 permissions, in /tmp (tmpfs)
 *   - Askpass helper: 0700 permissions, created once per opencode process
 *   - Cleanup on exit: both temp files deleted
 *
 * ## Limitations
 *
 *   - Only intercepts direct "bash" tool invocations; scripts or Makefiles
 *     that internally call sudo are NOT intercepted
 *   - sudo -A timeout (default 5 min) is not reset — agent may need to
 *     re-authenticate for long-running sessions
 */

import { unlinkSync } from "node:fs";

export const SudoHandlerPlugin = async ({
  project,
  client,
  $,
  directory,
  worktree,
}) => {
  let askpassReady = false;
  let askpassPath = null;

  /**
   * One-time setup: read the password and create the SUDO_ASKPASS
   * helper script. Safe to call multiple times — only runs once.
   */
  async function setupAskpass() {
    if (askpassReady) return;

    // Check environment variable and sync to temp file
    const envPass = process.env.OPENCODE_SUDO_PASS;
    if (envPass) {
      try {
        await $`printf '%s' ${envPass} > /tmp/opencode-sudo-pass`.quiet();
        await $`chmod 600 /tmp/opencode-sudo-pass`.quiet();
      } catch {
        // Non-fatal — fall through to try reading temp file
      }
    }

    // Try to read password from temp file
    try {
      const passResult = await $`cat /tmp/opencode-sudo-pass`.quiet();
      const pass = passResult.text().trim();

      if (pass) {
        askpassPath = `/tmp/opencode-askpass-${process.pid}.sh`;
        await $`printf '#!/bin/sh\ncat /tmp/opencode-sudo-pass\n' > ${askpassPath}`.quiet();
        await $`chmod 700 ${askpassPath}`.quiet();
        askpassReady = true;

        await client.app.log({
          body: {
            service: "sudo-handler",
            level: "info",
            message: "SUDO_ASKPASS helper created",
            extra: { askpassPath },
          },
        });
      }
    } catch {
      // No password file available — sudo commands will fail with TTY error
      await client.app.log({
        body: {
          service: "sudo-handler",
          level: "warn",
          message:
            "No sudo password available — sudo commands will fail without a TTY",
        },
      });
    }
  }

  // ── Cleanup on exit ────────────────────────────────────────────
  function cleanup() {
    try {
      unlinkSync("/tmp/opencode-sudo-pass");
    } catch {
      // File may already be gone
    }
    if (askpassPath) {
      try {
        unlinkSync(askpassPath);
      } catch {
        // File may already be gone
      }
    }
  }

  process.on("exit", cleanup);
  process.on("SIGTERM", () => {
    cleanup();
    process.exit();
  });
  process.on("SIGINT", () => {
    cleanup();
    process.exit();
  });

  // ── Hooks ──────────────────────────────────────────────────────

  return {
    /**
     * Inject SUDO_ASKPASS into every shell environment.
     *
     * This ensures sudo can authenticate via the askpass helper
     * rather than trying to read from a TTY (which doesn't exist
     * in opencode's shell execution context).
     */
    "shell.env": async (input, output) => {
      await setupAskpass();

      if (askpassReady) {
        output.env.SUDO_ASKPASS = askpassPath;
      }
    },

    /**
     * Detect sudo commands and rewrite them to use the askpass helper.
     *
     * - "sudo apt update"       → "sudo -A apt update"
     * - "sudo -E make install"  → "sudo -A -E make install"
     * - "echo x | sudo tee ..." → "echo x | sudo -A tee ..."
     *
     * Skips commands already using -A, -S (stdin), or -n (non-interactive).
     */
    "tool.execute.before": async (input, output) => {
      // Only handle bash tool invocations
      if (input.tool !== "bash") return;

      const cmd = output.args?.command;
      if (typeof cmd !== "string" || !cmd) return;

      // Check if the command uses sudo (but not already -A, -S, or -n)
      const sudoNeedsAskpass = /\bsudo\b(?!\s+-[ASn])/;
      if (!sudoNeedsAskpass.test(cmd)) return;

      // Ensure password is available
      await setupAskpass();

      if (askpassReady) {
        // Replace ALL sudo occurrences with "sudo -A"
        // The negative lookahead avoids double-wrapping -A, -S, -n
        output.args.command = cmd.replace(
          /\bsudo\b(?!\s+-[ASn])/g,
          "sudo -A"
        );

        await client.app.log({
          body: {
            service: "sudo-handler",
            level: "info",
            message: "Sudo command intercepted",
            extra: {
              original: cmd.slice(0, 200),
              rewritten: output.args.command.slice(0, 200),
              sessionID: input.sessionID,
            },
          },
        });
      }
      // If no password available: leave command unchanged.
      // sudo will fail with "no tty present" and the agent
      // can handle the error (ask user, try alternate approach).
    },
  };
};
