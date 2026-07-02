#!/usr/bin/env bash
# Touch-ID sudo autofill for Ghostty.
# Reads a sudo password from 1Password (Touch ID via the 1Password app CLI
# integration), then types it into the focused Ghostty terminal and presses Enter.
# Bind to a hotkey (skhd) and fire it at a "[sudo] password:" prompt.
#
# Guard: shell integration puts the running command in the terminal title, so
# the script only types when the title looks like a sudo prompt ("sudo", or
# "ssh" for sudo on a remote host). Anything else pops a confirmation dialog;
# a stray hotkey never pastes the password into an idle shell.
#
# The 1Password item reference is kept machine-local (not in this repo):
#   echo 'GHOSTTY_SUDO_OP_REF=op://<vault>/<item>/password' > ~/.config/ghostty-sudo-fill.env
set -euo pipefail

# skhd launches with a minimal PATH; make op + osascript resolvable.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:${PATH:-}"

env_file="$HOME/.config/ghostty-sudo-fill.env"
# shellcheck source=/dev/null
[ -f "$env_file" ] && . "$env_file"

note() { osascript -e "display notification \"$1\" with title \"sudo-fill\"" >/dev/null 2>&1 || true; }

if [ -z "${GHOSTTY_SUDO_OP_REF:-}" ]; then
  note "Set GHOSTTY_SUDO_OP_REF in ~/.config/ghostty-sudo-fill.env"
  exit 1
fi

# Shell integration titles a running command as the command line ("sudo ...",
# "ssh host") and an idle prompt as the cwd, so match only titles that START
# with sudo/ssh; "~/.ssh" or "vim sudoers" must not pass silently. The title
# is untrusted (remote escape sequences can set it), so it is never
# interpolated into AppleScript; it gates convenience only, and the real
# protections stay the deliberate hotkey press plus the 1Password Touch ID.
title="$(osascript -e 'tell application "Ghostty" to get name of focused terminal of selected tab of front window' 2>/dev/null || true)"
case "$title" in
  sudo | sudo\ * | ssh | ssh\ *) ;;
  *)
    if ! osascript -e 'display dialog "No sudo prompt detected in the focused terminal. Type the password anyway?" with title "sudo-fill" buttons {"Cancel", "Type"} default button "Cancel" cancel button "Cancel"' >/dev/null 2>&1; then
      note "Cancelled: no sudo prompt in focused terminal"
      exit 1
    fi
    ;;
esac

if ! pw="$("$HOME/.local/bin/op-cached" "$GHOSTTY_SUDO_OP_REF" 2>/dev/null)" || [ -z "$pw" ]; then
  note "op-cached failed (unlock 1Password / check item ref)"
  exit 1
fi

# Pass the secret via env (not argv) so it never appears in ps output.
PW="$pw" osascript <<'OSA' >/dev/null 2>&1
set pw to system attribute "PW"
tell application "Ghostty"
	set term to focused terminal of selected tab of front window
	input text pw to term
	send key "enter" to term
end tell
OSA
