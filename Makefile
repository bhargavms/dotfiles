# Dotfiles Makefile
# Usage: make install, make clean, make backup, etc.

.PHONY: install clean backup status help install-with-backup reinstall

# Default target
help:
	@echo "Available targets:"
	@echo "  install  - Install dotfiles (create symlinks)"
	@echo "  clean    - Remove symlinks and restore original files"
	@echo "  backup   - Backup existing dotfiles before installation"
	@echo "  status   - Show status of dotfiles (which are linked)"
	@echo "  install-with-backup - Create backup first, then install"
	@echo "  reinstall - Clean up existing symlinks and reinstall"
	@echo "  help     - Show this help message"

# Install dotfiles
install:
	@chmod +x scripts/install.sh
	@./scripts/install.sh

# Clean up symlinks
clean:
	@chmod +x scripts/clean.sh
	@./scripts/clean.sh

# Backup existing dotfiles
backup:
	@chmod +x scripts/backup.sh
	@./scripts/backup.sh

# Show status of dotfiles
status:
	@chmod +x scripts/status.sh
	@./scripts/status.sh

# Install with backup
install-with-backup:
	@chmod +x scripts/install-with-backup.sh
	@./scripts/install-with-backup.sh

# Reinstall (clean + install)
reinstall:
	@chmod +x scripts/reinstall.sh
	@./scripts/reinstall.sh 