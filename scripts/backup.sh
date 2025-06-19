#!/bin/bash

# Dotfiles backup script
# This script creates timestamped backups of existing dotfiles

set -e

echo "Creating backup of existing dotfiles..."

# Create backup directory with timestamp
BACKUP_DIR="backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup .zshrc if it exists and is not a symlink
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
    echo "Backed up .zshrc"
fi

# Backup oh-my-zsh custom if it exists and is not a symlink
if [ -d "$HOME/.oh-my-zsh/custom" ] && [ ! -L "$HOME/.oh-my-zsh/custom" ]; then
    cp -r "$HOME/.oh-my-zsh/custom" "$BACKUP_DIR/"
    echo "Backed up oh-my-zsh custom"
fi

echo "Backup complete! Files saved to: $BACKUP_DIR" 