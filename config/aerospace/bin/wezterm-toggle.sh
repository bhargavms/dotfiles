#!/usr/bin/env bash
# Super+` / Super+Enter: show the bottom WezTerm strip, or hide it.
set -euo pipefail
# shellcheck source=wezterm-dock.sh
source "$(dirname "$0")/wezterm-dock.sh"

if wezterm_is_shown; then
  hide_wezterm
else
  show_wezterm
fi
