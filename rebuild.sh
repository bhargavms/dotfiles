#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -eq 0 ]]; then
  echo "Run ./rebuild.sh as your normal user; it invokes sudo only for the system switch." >&2
  exit 1
fi
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if ! NIX="$(command -v nix)"; then
  echo "Nix is required. Install Determinate Nix, then open a new terminal and retry." >&2
  exit 1
fi
ln -sfn "$DIR" ~/.dotfiles
sudo "$NIX" run --no-update-lock-file \
  "$DIR#darwinConfigurations.mac.config.system.build.darwin-rebuild" \
  -- switch --flake "$DIR#mac" --no-update-lock-file
if [[ ! -x /opt/homebrew/bin/pre-commit ]]; then
  echo "System switch completed, but Homebrew pre-commit is missing; commit hooks were not installed." >&2
  exit 1
fi
(
  cd "$DIR"
  /opt/homebrew/bin/pre-commit install --install-hooks --overwrite
)
