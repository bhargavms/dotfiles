#!/bin/bash

# Dotfiles install with backup script
# This script creates a backup first, then installs dotfiles

set -e

echo "Installing dotfiles with backup..."

# Run backup first
./scripts/backup.sh

# Then install
./scripts/install.sh

echo "Installation with backup complete!" 