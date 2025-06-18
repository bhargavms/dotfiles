#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

# Create symlinks
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/oh-my-zsh-custom" "$HOME/.oh-my-zsh/custom"

echo "Symlinks created!"
