/**
 * sudo-prompt.tui.js — OpenCode TUI Plugin
 *
 * Collects the user's sudo password at startup so that sudo commands
 * executed by the agent can authenticate without hanging on a TTY prompt.
 *
 * ## Password collection (in order of priority)
 *
 *   1. OPENCODE_SUDO_PASS environment variable (pre-set, no prompt)
 *   2. Existing /tmp/opencode-sudo-pass file from a prior session
 *   3. ui.DialogPrompt shown at startup (plain text — no masking available)
 *
 * ## Storage
 *
 *   Password is written to /tmp/opencode-sudo-pass (tmpfs) with 0600
 *   permissions. The companion server plugin (sudo-handler.js) reads this
 *   file and feeds the password to sudo via SUDO_ASKPASS.
 *
 * ## Cleanup
 *
 *   The temp file is deleted when the TUI plugin is disposed (opencode exit).
 *
 * ## Limitations
 *
 *   - DialogPrompt shows text in plain text (TUI API has no password masking)
 *   - Password persists in /tmp until opencode exits or reboot
 */

import { writeFile, unlink, access } from "node:fs/promises";

/**
 * Register cleanup handler to remove the password temp file
 * when the plugin is disposed (opencode exits).
 */
function registerCleanup(api) {
  api.lifecycle.onDispose(async () => {
    try {
      await unlink("/tmp/opencode-sudo-pass");
    } catch {
      // File may already be deleted — ignore
    }
  });
}

/**
 * Prompt the user for their sudo password via a TUI dialog.
 * Returns the password string, or null if the user cancelled.
 */
function promptForPassword(api) {
  return new Promise((resolve) => {
    api.ui.dialog.replace(() =>
      api.ui.DialogPrompt({
        title:
          "Sudo Password (visible text — be mindful of surroundings)",
        placeholder: "Enter your sudo password",
        onConfirm: (value) => {
          api.ui.dialog.clear();
          resolve((value || "").trim() || null);
        },
        onCancel: () => {
          api.ui.dialog.clear();
          resolve(null);
        },
      })
    );
  });
}

export const tui = async (api, options, meta) => {
  // ── Priority 1: Environment variable ──────────────────────────
  const envPass = process.env.OPENCODE_SUDO_PASS;
  if (envPass) {
    await writeFile("/tmp/opencode-sudo-pass", envPass.trim(), {
      mode: 0o600,
    });
    api.ui.toast({
      title: "sudo",
      message: "Password loaded from OPENCODE_SUDO_PASS",
      variant: "info",
    });
    registerCleanup(api);
    return;
  }

  // ── Priority 2: Existing temp file (from prior session) ──────
  let hasExistingFile = false;
  try {
    await access("/tmp/opencode-sudo-pass");
    hasExistingFile = true;
  } catch {
    // File doesn't exist — will prompt
  }

  if (hasExistingFile) {
    api.ui.toast({
      title: "sudo",
      message: "Using cached sudo password from prior session",
      variant: "info",
    });
    registerCleanup(api);
    return;
  }

  // ── Priority 3: TUI dialog prompt ────────────────────────────
  const password = await promptForPassword(api);

  if (password) {
    await writeFile("/tmp/opencode-sudo-pass", password, { mode: 0o600 });
    api.ui.toast({
      title: "sudo",
      message: "Password saved for this session",
      variant: "success",
    });
  } else {
    api.ui.toast({
      title: "sudo",
      message: "No password provided — sudo commands may fail",
      variant: "warning",
    });
  }

  registerCleanup(api);
};
