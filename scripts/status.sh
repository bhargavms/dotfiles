#!/bin/bash

set -euo pipefail

echo "Dotfiles status:"
echo "=================="

check_link() {
    local target="$1"
    local label="$2"

    if [ -L "$target" ]; then
        echo "✓ $label is linked to: $(readlink "$target")"
    else
        echo "✗ $label is not linked"
    fi
}

check_link "$HOME/.zshrc" ".zshrc"
if [ -L "$HOME/.oh-my-zsh/custom" ]; then
    echo "✗ oh-my-zsh custom is a symlink (breaks omz update): $(readlink "$HOME/.oh-my-zsh/custom")"
elif [ -d "$HOME/.oh-my-zsh/custom" ]; then
    echo "✓ oh-my-zsh custom is a real directory"
else
    echo "✗ oh-my-zsh custom is missing"
fi
check_link "$HOME/.config/wezterm" "WezTerm config"
check_link "$HOME/.config/karabiner" "Karabiner config"
check_link "$HOME/.config/aerospace" "AeroSpace config"
check_link "$HOME/.config/gh/config.yml" "gh config.yml"
check_link "$HOME/.ideavimrc" ".ideavimrc"
