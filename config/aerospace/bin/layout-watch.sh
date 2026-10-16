#!/usr/bin/env bash
# Retile when a window leaves the focused workspace (close or move-away).
# AeroSpace has no on-window-closed config hook; focus-changed + count drop is the signal.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TILE_GRID="$SCRIPT_DIR/tile-grid.sh"
PIDFILE="${TMPDIR:-/tmp}/aerospace-layout-watch.pid"

if [[ -f "$PIDFILE" ]]; then
  old="$(cat "$PIDFILE" 2>/dev/null || true)"
  if [[ -n "$old" ]] && kill -0 "$old" 2>/dev/null; then
    kill "$old" 2>/dev/null || true
    # Give the previous subscribe socket a moment to drop
    sleep 0.1
  fi
fi
echo $$ >"$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

count_windows() {
  aerospace list-windows --workspace focused --format '%{window-id}' 2>/dev/null | grep -c . || true
}

prev_ws="$(aerospace list-workspaces --focused 2>/dev/null || true)"
prev_n="$(count_windows)"

while IFS= read -r _; do
  ws="$(aerospace list-workspaces --focused 2>/dev/null || true)"
  n="$(count_windows)"
  if [[ -n "$ws" && "$ws" == "$prev_ws" ]] && (( n < prev_n )); then
    env AEROSPACE_TILE_GRID_DEBOUNCE=1 "$TILE_GRID" &
  fi
  prev_ws="$ws"
  prev_n="$n"
done < <(aerospace subscribe --no-send-initial focus-changed)
