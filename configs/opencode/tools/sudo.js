/**
 * sudo.js — OpenCode Custom Tool
 *
 * Executes shell commands with sudo (elevated privileges).
 * Handles authentication transparently via SUDO_ASKPASS.
 *
 * ## Why a tool instead of a plugin
 *
 * Previously this was a server plugin that intercepted `tool.execute.before`
 * on the bash tool and regex-matched for `sudo` in the command string.
 * That approach was fragile — the regex missed many sudo patterns
 * (subshells, pipes, multi-line commands, etc.) and silent failures
 * left agents confused by cryptic "no tty present" errors.
 *
 * This custom tool is explicitly callable by the LLM, has a clear
 * contract (command in → output out), and provides actionable error
 * messages when the password isn't configured.
 *
 * ## Password sources (checked in order)
 *
 *   1. OPENCODE_SUDO_PASS environment variable
 *   2. /tmp/opencode-sudo-pass temp file (created by opencode-sudo-setup.sh)
 *
 * ## Setup (pick one)
 *
 *   # Option A: Run setup script (one-time per session)
 *   bash ~/dotfiles/scripts/opencode-sudo-setup.sh
 *
 *   # Option B: Environment variable (ephemeral, per-session)
 *   export OPENCODE_SUDO_PASS='your-password'
 *   opencode
 *
 * ## Usage (from agent)
 *
 *   Call the `sudo` tool with a `command` parameter.
 *   Do NOT include the 'sudo' prefix.
 *
 *   Correct:  sudo tool → command: "apt update"
 *   Wrong:    bash tool → "sudo apt update"
 */

import { tool } from "@opencode-ai/plugin";
import { execSync } from "node:child_process";
import { existsSync, writeFileSync, unlinkSync } from "node:fs";

export default tool({
  description: [
    "Execute a shell command with sudo (elevated privileges).",
    "",
    "Use this tool instead of prefixing commands with `sudo` in the bash tool.",
    "",
    "Typical use cases:",
    "- Install/remove system packages (apt, dnf, pacman, etc.)",
    "- Edit or create files in /etc, /usr, /opt, and other protected paths",
    "- Manage system services (systemctl, service, etc.)",
    "- Read protected log files (/var/log/*)",
    "- Modify file permissions or ownership",
    "- Any command that requires root access",
  ].join("\n"),

  args: {
    command: tool.schema
      .string()
      .describe(
        "The shell command to execute with root privileges. " +
          "Do NOT include the 'sudo' prefix — this is added automatically.",
      ),
  },

  async execute(args, { sessionID, agent }) {
    const { command } = args;
    const passFile = "/tmp/opencode-sudo-pass";
    const envPass = process.env.OPENCODE_SUDO_PASS;
    const askpassPath = `/tmp/opencode-askpass-${process.pid}.sh`;

    // ── Check password availability ──────────────────────────────
    if (!existsSync(passFile) && !envPass) {
      return [
        "",
        "  ❌ Sudo password not configured.",
        "",
        "  To enable sudo access for opencode, run this in your terminal:",
        "    bash ~/dotfiles/scripts/opencode-sudo-setup.sh",
        "",
        "  Or set the environment variable before starting opencode:",
        "    export OPENCODE_SUDO_PASS='your-password'",
        "    opencode",
        "",
      ].join("\n");
    }

    // ── Create askpass helper script ─────────────────────────────
    try {
      if (envPass) {
        // Escape special characters for the shell script context
        const escaped = envPass.replace(/[\\"$`]/g, "\\$&");
        writeFileSync(askpassPath, `#!/bin/sh\necho "${escaped}"\n`, {
          mode: 0o700,
        });
      } else {
        writeFileSync(askpassPath, `#!/bin/sh\ncat ${passFile}\n`, {
          mode: 0o700,
        });
      }

      // ── Execute via shell (preserves pipes, redirects, etc.) ──
      const result = execSync(
        `SUDO_ASKPASS=${askpassPath} sudo -A ${command}`,
        {
          encoding: "utf-8",
          shell: "/bin/bash",
          timeout: 120_000,
          maxBuffer: 10 * 1024 * 1024,
          windowsHide: true,
        },
      );

      return result.replace(/\n$/, "");
    } catch (err) {
      const lines = [`Exit code: ${err.status || "?"}`];
      if (err.stdout) lines.push(err.stdout.replace(/\n$/, ""));
      if (err.stderr) lines.push(err.stderr.replace(/\n$/, ""));
      if (!err.stdout && !err.stderr) lines.push(err.message);
      return lines.join("\n");
    } finally {
      // Remove askpass script immediately — it contains the password
      try {
        unlinkSync(askpassPath);
      } catch {
        // Non-fatal cleanup failure
      }
    }
  },
});
