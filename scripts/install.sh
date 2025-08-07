#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

# Create symlinks
echo "Creating sym links for zshrc and oh-my-zsh custom"
## oh my zsh setup
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
rm -rf "$HOME/.oh-my-zsh/custom"
cp -r "$DOTFILES_DIR/oh-my-zsh-custom" "$HOME/.oh-my-zsh/custom"

## wezterm
mkdir -p $HOME/.config/
cp -r $DOTFILES_DIR/wezterm $HOME/.config/

## install fonts
bash ./install_fonts.sh

echo "Installation Complete!"

