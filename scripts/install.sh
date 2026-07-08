#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

link_file() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"
    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

link_dir() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"
    rm -rf "$target"
    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

echo "Creating symlinks from $DOTFILES_DIR"

## oh my zsh setup
link_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
link_dir "$DOTFILES_DIR/oh-my-zsh-custom" "$HOME/.oh-my-zsh/custom"

## wezterm
link_dir "$DOTFILES_DIR/wezterm" "$HOME/.config/wezterm"

## install fonts
bash "$SCRIPT_DIR/install_fonts.sh"

## install jetbrains/android studio configurations
link_file "$DOTFILES_DIR/ideavimrc" "$HOME/.ideavimrc"

echo "Installation Complete!"
