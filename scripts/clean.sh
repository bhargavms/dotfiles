#!/bin/bash

set -euo pipefail

echo "Cleaning up dotfiles..."

remove_link() {
    local target="$1"
    local label="$2"

    if [ -L "$target" ]; then
        echo "Removing $label symlink..."
        rm "$target"
    fi
}

remove_link "$HOME/.config/wezterm" "WezTerm config"
remove_link "$HOME/.config/karabiner" "Karabiner config"
remove_link "$HOME/.config/aerospace" "AeroSpace config"
remove_link "$HOME/.config/gh/config.yml" "gh config.yml"
remove_link "$HOME/.ideavimrc" ".ideavimrc"

echo "Cleanup complete!"
