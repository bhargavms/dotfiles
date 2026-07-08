#!/bin/bash

# Dotfiles cleanup script
# This script removes symlinks created by the installation

set -e

echo "Cleaning up dotfiles..."

# Remove .zshrc symlink if it exists
if [ -L "$HOME/.zshrc" ]; then
    echo "Removing .zshrc symlink..."
    rm "$HOME/.zshrc"
fi

# Remove oh-my-zsh custom symlink if it exists
if [ -L "$HOME/.oh-my-zsh/custom" ]; then
    echo "Removing oh-my-zsh custom symlink..."
    rm "$HOME/.oh-my-zsh/custom"
fi

# Remove WezTerm symlink if it exists
if [ -L "$HOME/.config/wezterm" ]; then
    echo "Removing WezTerm config symlink..."
    rm "$HOME/.config/wezterm"
fi

# Remove .ideavimrc symlink if it exists
if [ -L "$HOME/.ideavimrc" ]; then
    echo "Removing .ideavimrc symlink..."
    rm "$HOME/.ideavimrc"
fi

echo "Cleanup complete!"
