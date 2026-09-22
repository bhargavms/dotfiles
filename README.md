# Dotfiles

Personal macOS setup: nix-darwin, home-manager, and nix-homebrew. The flake host is `mac`.

Clone this repo anywhere; `./rebuild.sh` points `~/.dotfiles` at it and applies the flake. home-manager generates `~/.zshrc` (Starship, not Oh My Zsh). Aliases live in `zsh/aliases.nix`; Git helper functions live in `zsh/git-functions.nix`. XDG apps live under `config/` and map 1:1 onto `~/.config` as out-of-store symlinks.

## Prerequisites

- Git
- [Determinate Nix](https://docs.determinate.systems/determinate-nix/) — nix-darwin is applied with `./rebuild.sh`

### Optional: Pi binary caches

Nix is managed by Determinate (`nix.enable = false` in darwin), so caches are not set from this flake. To avoid building [Pi](https://pi.dev/) from source, add these lines once to `/etc/nix/nix.custom.conf` (sudo), then restart the Nix daemon if needed:

```
extra-substituters = https://pi.cachix.org https://nix-community.cachix.org
extra-trusted-public-keys = pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
```

Do not use `--accept-flake-config` for this.

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
| `flake.nix` | Inputs (nixpkgs 26.05, nix-darwin, home-manager, nix-homebrew, [pi.nix](https://github.com/lukasl-dev/pi.nix)) and `darwinConfigurations.mac` |
| `configuration.nix` | macOS defaults, [0xProto Nerd Font](https://github.com/ryanoasis/nerd-fonts), Homebrew taps/formulae/casks (`cleanup = zap`) |
| `home.nix` | User packages (nvim, Go, Java, Rust, LSPs, formatters), Pi coding agent (`programs.pi.coding-agent`), `programs.zsh`, Starship, config links |
| `zsh/aliases.nix` | `shellAliases` (git, gradle, codex, …) |
| `zsh/git-functions.nix` | `initContent` helpers: `git_main_branch`, `gpur`, `gCleanB`, `gsquash` |
| `.pre-commit-config.yaml` | Repo git hooks; `pre-commit` is a Homebrew formula. Run `pre-commit install` once in this clone. |

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
- **Pi provider API keys / auth** — configure interactively with `pi` after install; agent state lives under `~/.pi/agent` (not in this repo).

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
- **Prompt / packages / env / Pi** — edit `home.nix` (`programs.pi.coding-agent` for rules, skills, settings).
- **Homebrew / macOS defaults / fonts** — edit `configuration.nix`.
- **WezTerm, Karabiner, AeroSpace, IdeaVim** — edit in this repo (or via the live `~/.config` / `~/.ideavimrc` links).

Apply Nix changes with `./rebuild.sh`, then `exec zsh -l`. On another machine: clone, then `./rebuild.sh`.
