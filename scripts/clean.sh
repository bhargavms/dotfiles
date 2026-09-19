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

remove_link "$HOME/.zshrc" ".zshrc"
if [ -L "$HOME/.oh-my-zsh/custom" ]; then
    echo "Removing oh-my-zsh custom symlink..."
    rm "$HOME/.oh-my-zsh/custom"
    if [ -d "$HOME/.oh-my-zsh/.git" ]; then
        git -C "$HOME/.oh-my-zsh" checkout -- custom
        echo "Restored ~/.oh-my-zsh/custom from the Oh My Zsh git repo"
    fi
fi
remove_link "$HOME/.config/wezterm" "WezTerm config"
remove_link "$HOME/.config/karabiner" "Karabiner config"
remove_link "$HOME/.config/aerospace" "AeroSpace config"
remove_link "$HOME/.config/gh/config.yml" "gh config.yml"
remove_link "$HOME/.ideavimrc" ".ideavimrc"

echo "Cleanup complete!"
