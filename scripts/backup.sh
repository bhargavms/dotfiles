#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Creating backup of existing dotfiles..."

BACKUP_DIR="$DOTFILES_DIR/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

backup_file() {
    local source="$1"
    local dest_name="$2"

    if [ -f "$source" ] && [ ! -L "$source" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR/$dest_name")"
        cp "$source" "$BACKUP_DIR/$dest_name"
        echo "Backed up $source"
    fi
}

backup_dir() {
    local source="$1"
    local dest_name="$2"

    if [ -d "$source" ] && [ ! -L "$source" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR/$dest_name")"
        cp -R "$source" "$BACKUP_DIR/$dest_name"
        echo "Backed up $source"
    fi
}

backup_file "$HOME/.zshrc" ".zshrc"
backup_dir "$HOME/.config/wezterm" "wezterm"
backup_dir "$HOME/.config/karabiner" "karabiner"
backup_dir "$HOME/.config/aerospace" "aerospace"
backup_file "$HOME/.config/gh/config.yml" "gh/config.yml"
backup_file "$HOME/.ideavimrc" ".ideavimrc"

echo "Backup complete! Files saved to: $BACKUP_DIR"
