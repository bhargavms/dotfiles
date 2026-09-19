#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

assert_safe_target() {
    local target="${1%/}"
    local nvim="$HOME/.config/nvim"
    local gh_dir="$HOME/.config/gh"

    if [ "$target" = "$nvim" ] || [[ "$target" == "$nvim/"* ]]; then
        echo "Refusing to modify $target (nvim is managed separately)" >&2
        exit 1
    fi

    if [ "$target" = "$gh_dir" ]; then
        echo "Refusing to replace $target (hosts.yml must stay local)" >&2
        exit 1
    fi
}

link_file() {
    local source="$1"
    local target="$2"

    assert_safe_target "$target"
    mkdir -p "$(dirname "$target")"
    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

link_dir() {
    local source="$1"
    local target="$2"

    assert_safe_target "$target"
    mkdir -p "$(dirname "$target")"
    rm -rf "$target"
    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

echo "Initializing submodules in $DOTFILES_DIR"
git -C "$DOTFILES_DIR" submodule update --init --recursive

echo "Creating symlinks from $DOTFILES_DIR"

## oh my zsh setup
link_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
link_dir "$DOTFILES_DIR/oh-my-zsh-custom" "$HOME/.oh-my-zsh/custom"

## XDG config (never nvim, never the whole gh/ directory)
link_dir "$DOTFILES_DIR/config/wezterm" "$HOME/.config/wezterm"
link_dir "$DOTFILES_DIR/config/karabiner" "$HOME/.config/karabiner"
link_dir "$DOTFILES_DIR/config/aerospace" "$HOME/.config/aerospace"
link_file "$DOTFILES_DIR/config/gh/config.yml" "$HOME/.config/gh/config.yml"

## install fonts
bash "$SCRIPT_DIR/install_fonts.sh"

## install jetbrains/android studio configurations
link_file "$DOTFILES_DIR/ideavimrc" "$HOME/.ideavimrc"

echo "Installation Complete!"
