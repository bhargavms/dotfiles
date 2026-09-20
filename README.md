# Dotfiles

Personal macOS setup: nix-darwin, home-manager, and nix-homebrew. The flake host is `mac`.

Clone this repo anywhere; `./rebuild.sh` points `~/.dotfiles` at it and applies the flake. home-manager generates `~/.zshrc` (Starship, not Oh My Zsh). Aliases live in `zsh/aliases.nix`; Git helper functions live in `zsh/git-functions.nix`. XDG apps live under `config/` and map 1:1 onto `~/.config` as out-of-store symlinks.

## Prerequisites

- Git
- [Determinate Nix](https://docs.determinate.systems/determinate-nix/) — nix-darwin is applied with `./rebuild.sh`

## Install

```bash
git clone git@github.com:bhargavms/dotfiles.git
cd dotfiles
./rebuild.sh
exec zsh -l
```

`./rebuild.sh` creates `~/.dotfiles` and runs `darwin-rebuild switch --flake ~/.dotfiles#mac`. That installs Homebrew packages from `configuration.nix`, Nix packages, fonts, and the shell from the flake, and links the configs below.

## What Nix owns

| File | Role |
|------|------|
| `flake.nix` | Inputs (nixpkgs 26.05, nix-darwin, home-manager, nix-homebrew) and `darwinConfigurations.mac` |
| `configuration.nix` | macOS defaults, [0xProto Nerd Font](https://github.com/ryanoasis/nerd-fonts), Homebrew taps/formulae/casks (`cleanup = zap`) |
| `home.nix` | User packages (nvim, Go, Java, LSPs, formatters), `programs.zsh`, Starship, config links, pre-commit hook install |
| `zsh/aliases.nix` | `shellAliases` (git, gradle, codex, …) |
| `zsh/git-functions.nix` | `initContent` helpers: `git_main_branch`, `gpur`, `gCleanB`, `gsquash` |
| `.pre-commit-config.yaml` | Repo git hooks; `pre-commit` is a Homebrew formula |

Neovim **config** is not in this repo (see below). The `neovim` package and language servers/formatters are.

## What gets linked

home-manager (`mkOutOfStoreSymlink`) points these at the repo:

| Source | Target |
|--------|--------|
| `ideavimrc` | `~/.ideavimrc` |
| `config/wezterm/` | `~/.config/wezterm` |
| `config/karabiner/` | `~/.config/karabiner` |
| `config/aerospace/` | `~/.config/aerospace` |
| `config/gh/config.yml` | `~/.config/gh/config.yml` |

Edit them in the repo; `~/.config` is a live symlink, not a Nix store copy.

## Not managed

- **Neovim** — separate repo at [`my-nvim`](https://github.com/bhargavms/my-nvim); clone it to `~/.config/nvim`. This flake does not touch that path.
- **`~/.config/gh/hosts.yml`** — local GitHub CLI auth; only `config.yml` is linked.
- Caches and app state under `~/.config` (qBittorrent and similar).
- `~/.gitconfig`, secrets (`TFE_TOKEN`, Terraform credentials, SSH keys).

Karabiner automatic backups and WezTerm `workspace-states/` are gitignored if they appear next to the tracked files.

## Layout

```
.
├── flake.nix
├── flake.lock
├── configuration.nix
├── home.nix
├── rebuild.sh
├── .pre-commit-config.yaml
├── .githooks/pre-commit
├── zsh/
│   ├── aliases.nix
│   └── git-functions.nix
├── ideavimrc
└── config/
    ├── wezterm/
    ├── karabiner/karabiner.json
    ├── aerospace/aerospace.toml
    └── gh/config.yml
```

## Day to day

- **Shell aliases** — edit `zsh/aliases.nix`.
- **Git functions** — edit `zsh/git-functions.nix`.
- **Prompt / packages / env** — edit `home.nix`.
- **Homebrew / macOS defaults / fonts** — edit `configuration.nix`.
- **WezTerm, Karabiner, AeroSpace, IdeaVim** — edit in this repo (or via the live `~/.config` / `~/.ideavimrc` links).

Apply Nix changes with `./rebuild.sh`, then `exec zsh -l`. On another machine: clone, then `./rebuild.sh`.
