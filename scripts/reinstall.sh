#!/bin/bash

# Dotfiles reinstall script
# This script cleans up existing symlinks and reinstalls dotfiles

set -e

echo "Reinstalling dotfiles..."

# Clean up first
./scripts/clean.sh

# Then install
./scripts/install.sh

echo "Reinstallation complete!" 