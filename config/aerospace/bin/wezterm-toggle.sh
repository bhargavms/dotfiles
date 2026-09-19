#!/usr/bin/env bash
# Toggle the shared floating WezTerm: show/focus, or hide if already focused.
set -euo pipefail

id="$(aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' \
  | awk '$2 == "com.github.wez.wezterm" { print $1; exit }')"

if [[ -z "${id:-}" ]]; then
  open -na WezTerm
  exit 0
fi

focused="$(aerospace list-windows --focused --format '%{window-id}')"
ws="$(aerospace list-workspaces --focused)"

if [[ "$focused" == "$id" ]]; then
  aerospace move-node-to-workspace --window-id "$id" scratch || true
  exit 0
fi

aerospace move-node-to-workspace --window-id "$id" "$ws" || true
aerospace layout floating --window-id "$id" || true
aerospace focus --window-id "$id" || true
