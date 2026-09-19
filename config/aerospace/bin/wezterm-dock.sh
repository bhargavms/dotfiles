#!/usr/bin/env bash
# Dock WezTerm as a bottom strip (20% of the screen) and push tiled windows up.
# Used by wezterm-toggle.sh and wezterm-follow.sh.
set -euo pipefail

CONFIG="${AEROSPACE_CONFIG:-$HOME/.config/aerospace/aerospace.toml}"
BUNDLE_ID="com.github.wez.wezterm"
REST_GAP=8

wezterm_id() {
  aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' \
    | awk -v id="$BUNDLE_ID" '$2 == id { print $1; exit }'
}

wezterm_workspace() {
  local id="$1"
  aerospace list-windows --all --format '%{window-id} %{workspace} %{app-bundle-id}' \
    | awk -v wid="$id" '$1 == wid { print $2; exit }'
}

visible_frame() {
  osascript -l JavaScript <<'JXA'
ObjC.import("AppKit");
const vf = $.NSScreen.mainScreen.visibleFrame;
const frame = $.NSScreen.mainScreen.frame;
const menu = frame.size.height - vf.size.height - vf.origin.y;
`${vf.origin.x} ${menu} ${vf.size.width} ${vf.size.height}`;
JXA
}

set_bottom_gap() {
  local px="$1"
  perl -i -pe "s/^gaps\\.outer\\.bottom = .*/gaps.outer.bottom = ${px}/" "$CONFIG"
  aerospace reload-config || true
}

place_wezterm() {
  local x menu w h gap
  read -r x menu w h <<<"$(visible_frame)"
  gap=$((h * 20 / 100))
  # WezTerm.lua reads this file and moves the window (no Accessibility needed)
  printf '%s %s %s %s %s\n' "$x" "$((menu + h - gap))" "$w" "$gap" "$$" \
    > "${HOME}/.config/aerospace/.wezterm-dock"
}

show_wezterm() {
  local id ws x menu w h gap
  id="$(wezterm_id)"
  if [[ -z "${id:-}" ]]; then
    open -na WezTerm
    local i
    for i in {1..25}; do
      id="$(wezterm_id || true)"
      [[ -n "${id:-}" ]] && break
      sleep 0.1
    done
  fi
  [[ -z "${id:-}" ]] && exit 1

  read -r x menu w h <<<"$(visible_frame)"
  gap=$((h * 20 / 100))
  ws="$(aerospace list-workspaces --focused)"

  set_bottom_gap "$gap"
  aerospace move-node-to-workspace --window-id "$id" "$ws" || true
  aerospace layout floating --window-id "$id" || true
  sleep 0.2
  place_wezterm || true
  aerospace focus --window-id "$id" || true
  sleep 0.2
  place_wezterm || true
}

hide_wezterm() {
  local id
  id="$(wezterm_id || true)"
  if [[ -n "${id:-}" ]]; then
    aerospace move-node-to-workspace --window-id "$id" scratch || true
  fi
  rm -f "${HOME}/.config/aerospace/.wezterm-dock"
  set_bottom_gap "$REST_GAP"
}

wezterm_is_shown() {
  local id ws
  id="$(wezterm_id || true)"
  [[ -z "${id:-}" ]] && return 1
  ws="$(wezterm_workspace "$id")"
  [[ -n "$ws" && "$ws" != "scratch" ]]
}
