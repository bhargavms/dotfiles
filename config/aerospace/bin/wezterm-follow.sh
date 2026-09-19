#!/usr/bin/env bash
# Keep the floating WezTerm on whatever workspace is focused.
set -euo pipefail

ws="${AEROSPACE_FOCUSED_WORKSPACE:-}"
if [[ -z "$ws" ]]; then
  ws="$(aerospace list-workspaces --focused)"
fi
[[ -z "$ws" ]] && exit 0

while IFS= read -r line; do
  id="${line%% *}"
  app="${line#* }"
  if [[ "$app" == "com.github.wez.wezterm" ]]; then
    aerospace move-node-to-workspace --window-id "$id" "$ws" || true
    aerospace layout floating --window-id "$id" || true
  fi
done < <(aerospace list-windows --all --format '%{window-id} %{app-bundle-id}')
