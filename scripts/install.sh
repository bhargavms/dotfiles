#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

# Create symlinks
echo "Creating sym links for zshrc and oh-my-zsh custom"
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/oh-my-zsh-custom" "$HOME/.oh-my-zsh/custom"

echo "Installation Complete!"

