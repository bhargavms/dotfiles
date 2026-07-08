#!/bin/bash

# Dotfiles status script
# This script shows the status of dotfiles and their symlinks

echo "Dotfiles status:"
echo "=================="

# Check .zshrc status
if [ -L "$HOME/.zshrc" ]; then
    echo "✓ .zshrc is linked to: $(readlink "$HOME/.zshrc")"
else
    echo "✗ .zshrc is not linked"
fi

# Check oh-my-zsh custom status
if [ -L "$HOME/.oh-my-zsh/custom" ]; then
    echo "✓ oh-my-zsh custom is linked to: $(readlink "$HOME/.oh-my-zsh/custom")"
else
    echo "✗ oh-my-zsh custom is not linked"
fi

# Check WezTerm status
if [ -L "$HOME/.config/wezterm" ]; then
    echo "✓ WezTerm config is linked to: $(readlink "$HOME/.config/wezterm")"
else
    echo "✗ WezTerm config is not linked"
fi

# Check IdeaVim status
if [ -L "$HOME/.ideavimrc" ]; then
    echo "✓ .ideavimrc is linked to: $(readlink "$HOME/.ideavimrc")"
else
    echo "✗ .ideavimrc is not linked"
fi
