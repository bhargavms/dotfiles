#!/usr/bin/env bash
# Arrange tiling windows on the focused workspace into a 2x2 grid:
#   top-left | top-right
#   ---------+----------
#   bot-left | bot-right
set -u

is_excluded() {
  case "$1" in
    com.apple.systempreferences|com.apple.AppStore) return 0 ;;
  esac
  return 1
}

ids=()
apps=()
while IFS= read -r line; do
  id="${line%% *}"
  app="${line#* }"
  is_excluded "$app" && continue
  ids+=("$id")
  apps+=("$app")
done < <(aerospace list-windows --workspace focused --format '%{window-id} %{app-bundle-id}')

n=${#ids[@]}
(( n == 0 )) && exit 0

pick() {
  local want="$1"
  local i
  for i in "${!apps[@]}"; do
    if [[ "${apps[$i]}" == "$want" ]]; then
      echo "${ids[$i]}"
      return 0
    fi
  done
  return 1
}

# Prefer a stable 2x2 when the usual four apps are present
if cursor="$(pick com.todesktop.230313mzl4w4u92)" \
  && anti="$(pick com.google.antigravity)" \
  && arc="$(pick company.thebrowser.Browser)" \
  && mail="$(pick com.apple.mail)"; then
  ids=("$cursor" "$anti" "$arc" "$mail")
  n=4
fi

ws="$(aerospace list-workspaces --focused)"
tmp="10"
if [[ "$ws" == "10" ]]; then
  tmp="9"
fi

# Re-insert in TL, BL, TR, BR order so join-with right can form two columns
if (( n >= 4 )); then
  for id in "${ids[@]:0:4}"; do
    aerospace move-node-to-workspace --window-id "$id" "$tmp" || true
  done
  for id in "${ids[@]:0:4}"; do
    aerospace move-node-to-workspace --window-id "$id" "$ws" || true
  done
fi

aerospace flatten-workspace-tree
aerospace layout --root tiles || true
aerospace layout --root horizontal || true

join_with() {
  local id="$1"
  local dir out
  for dir in right down left up; do
    out="$(aerospace join-with "$dir" --window-id "$id" 2>&1)" || true
    if [[ "$out" != *"No windows"* && "$out" != *"ERROR"* ]]; then
      return 0
    fi
  done
  return 1
}

if (( n == 3 )); then
  # left half + stacked right half
  join_with "${ids[1]}" || true
  exit 0
fi

if (( n >= 4 )); then
  join_with "${ids[0]}" || true
  join_with "${ids[2]}" || true
fi
