/**
 * sudo-handler.js — OpenCode Server Plugin
 *
 * Intercepts sudo commands and injects an inline SUDO_ASKPASS
 * environment variable so sudo authenticates without a TTY.
 *
 * ## How it works
 *
 *   tool.execute.before (bash + contains "sudo")
 *     │
 *     ├─ Password available? (OPENCODE_SUDO_PASS or /tmp/opencode-sudo-pass)
 *     │   └─ Yes → Create askpass helper script (one-time)
 *     │           Rewrite: sudo cmd → SUDO_ASKPASS=... sudo -A cmd
 *     │
 *     └─ No  → Leave command unchanged
 *              sudo fails → agent sees error → can ask user
 *
 * ## Password sources (checked in order)
 *
 *   1. OPENCODE_SUDO_PASS environment variable
 *   2. /tmp/opencode-sudo-pass temp file (created by opencode-sudo-setup.sh)
 *
 * ## Setup (pick one)
 *
 *   # Option A: env var (ephemeral, per-session)
 *   export OPENCODE_SUDO_PASS='your-password'
 *   opencode
 *
 *   # Option B: helper script (stores in /tmp, persists until reboot)
 *   bash ~/dotfiles/scripts/opencode-sudo-setup.sh
 *   opencode
 *
 * ## Requirements
 *
 *   - opencode >= 1.14.x (uses tool.execute.before hook)
 *   - sudo configured to allow the user (standard)
 *
 * ## Limitations
 *
 *   - Only intercepts direct "bash" tool invocations
 *   - SUDO_ASKPASS is visible in the command string (process list)
 *     for the brief moment the command runs
 */

import { unlinkSync } from "node:fs";

export const SudoHandlerPlugin = async ({ project, client, $ }) => {
  let askpassReady = false;
  let askpassPath = null;

  /**
   * One-time setup: locate the password and create the SUDO_ASKPASS
   * helper script. Safe to call multiple times — only runs once.
   */
  async function setupAskpass() {
    if (askpassReady) return;

    // Priority 1: Environment variable → sync to temp file
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
        // Write a one-line askpass script that echoes the password
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
      await client.app.log({
        body: {
          service: "sudo-handler",
          level: "warn",
          message:
            "No sudo password available — sudo commands will fail without a TTY. " +
            "Run: bash ~/dotfiles/scripts/opencode-sudo-setup.sh",
        },
      });
    }
  }

  // ── Cleanup temp files on exit ────────────────────────────────
  function cleanup() {
    try { unlinkSync("/tmp/opencode-sudo-pass"); } catch {}
    if (askpassPath) {
      try { unlinkSync(askpassPath); } catch {}
    }
  }

  process.on("exit", cleanup);
  process.on("SIGTERM", () => { cleanup(); process.exit(); });
  process.on("SIGINT", () => { cleanup(); process.exit(); });

  // ── Hook ──────────────────────────────────────────────────────

  return {
    /**
     * Intercept bash commands that use sudo.
     *
     * Rewrites "sudo cmd" to "SUDO_ASKPASS=... sudo -A cmd"
     * so sudo authenticates via the askpass helper instead of
     * trying to read from a non-existent TTY.
     *
     * Skips commands already using -A (askpass), -S (stdin),
     * or -n (non-interactive).
     */
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return;

      const cmd = output.args?.command;
      if (typeof cmd !== "string" || !cmd) return;

      // Check if command uses sudo (but not already -A, -S, or -n)
      const sudoNeedsAskpass = /\bsudo\b(?!\s+-[ASn])/;
      if (!sudoNeedsAskpass.test(cmd)) return;

      // Ensure password and askpass helper are ready
      await setupAskpass();

      if (askpassReady) {
        // Prefix SUDO_ASKPASS env var and append -A to sudo
        const rewritten = cmd.replace(
          /\bsudo\b(?!\s+-[ASn])/g,
          "sudo -A"
        );
        output.args.command = `SUDO_ASKPASS=${askpassPath} ${rewritten}`;

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
      // If no password: leave unchanged. sudo will fail with
      // "no tty present" and the agent can adapt.
    },
  };
};
