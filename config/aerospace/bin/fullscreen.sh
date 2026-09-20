#!/usr/bin/env bash
# Super+F: WezTerm dock <-> full screen, otherwise normal AeroSpace fullscreen.
set -euo pipefail
# shellcheck source=wezterm-dock.sh
source "$(dirname "$0")/wezterm-dock.sh"

app="$(aerospace list-windows --focused --format '%{app-bundle-id}')"
if [[ "$app" == "com.github.wez.wezterm" ]]; then
  toggle_wezterm_fullscreen
  exit 0
fi

aerospace fullscreen
