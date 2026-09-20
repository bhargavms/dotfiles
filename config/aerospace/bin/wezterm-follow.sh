#!/usr/bin/env bash
# If the bottom WezTerm strip is open, keep it on the focused workspace.
set -euo pipefail
# shellcheck source=wezterm-dock.sh
source "$(dirname "$0")/wezterm-dock.sh"

ws="${AEROSPACE_FOCUSED_WORKSPACE:-}"
if [[ -z "$ws" ]]; then
  ws="$(aerospace list-workspaces --focused)"
fi
[[ -z "$ws" || "$ws" == "scratch" ]] && exit 0

id="$(wezterm_id || true)"
[[ -z "${id:-}" ]] && exit 0

cur="$(wezterm_workspace "$id")"
[[ "$cur" == "scratch" ]] && exit 0

aerospace move-node-to-workspace --window-id "$id" "$ws" || true
aerospace layout floating --window-id "$id" || true
if wezterm_is_full; then
  aerospace fullscreen on --window-id "$id" || true
else
  place_wezterm || true
fi
