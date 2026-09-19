# Dotfiles

Personal macOS dotfiles. The repo lives wherever you clone it; `make install` symlinks the tracked files into `$HOME`.

XDG apps live under `config/` and map 1:1 onto `~/.config`. Shell and IdeaVim files stay at the repo root.

## Prerequisites

- Git
- [Oh My Zsh](https://ohmyz.sh/) at `~/.oh-my-zsh` (this repo only replaces `custom/`)
- Homebrew (for `brew shellenv` in `zshrc`)

Install also downloads [0xProto Nerd Font](https://github.com/ryanoasis/nerd-fonts) into `~/Library/Fonts`.

## Install

```bash
git clone git@github.com:bhargavms/dotfiles.git
cd dotfiles
make install-with-backup
```

`make install` runs `git submodule update --init --recursive`, then creates the symlinks below. `link_dir` **replaces** the target path (`rm -rf`), so use `install-with-backup` on a machine that already has configs.

After the first shell with Powerlevel10k, run `p10k configure`. `~/.p10k.zsh` is not tracked here.

## What gets linked

| Source | Target |
|--------|--------|
| `zshrc` | `~/.zshrc` |
| `oh-my-zsh-custom/` | `~/.oh-my-zsh/custom` |
| `ideavimrc` | `~/.ideavimrc` |
| `config/wezterm/` | `~/.config/wezterm` |
| `config/karabiner/` | `~/.config/karabiner` |
| `config/aerospace/` | `~/.config/aerospace` |
| `config/gh/config.yml` | `~/.config/gh/config.yml` |

## Not managed

- **Neovim** — separate repo at [`my-nvim`](https://github.com/bhargavms/my-nvim); clone it to `~/.config/nvim`. Install refuses to touch that path.
- **`~/.config/gh/hosts.yml`** — local GitHub CLI auth; only `config.yml` is linked.
- Caches and app state under `~/.config` (qBittorrent, tfenv, and similar).
- `~/.p10k.zsh`, `~/.gitconfig`, secrets (`TFE_TOKEN`, Terraform credentials, SSH keys).

Karabiner automatic backups and WezTerm `workspace-states/` are gitignored if they appear next to the tracked files.

## Layout

```
.
├── zshrc
├── ideavimrc
├── config/
│   ├── wezterm/
│   ├── karabiner/karabiner.json
│   ├── aerospace/aerospace.toml
│   └── gh/config.yml
├── oh-my-zsh-custom/          # aliases + plugin/theme submodules
└── scripts/
```

Third-party Oh My Zsh extras are git submodules:

- [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

## Make targets

| Target | What it does |
|--------|----------------|
| `make install` | Init submodules, symlink, install fonts |
| `make backup` | Copy existing non-symlink files into `backup/<timestamp>/` |
| `make install-with-backup` | Backup, then install |
| `make status` | Show which targets are symlinks into this repo |
| `make clean` | Remove those symlinks (does not restore backups) |
| `make reinstall` | Clean, then install |

## Day to day

Edit files in this repo or under `~` / `~/.config` — they are the same files, not copies. WezTerm, Karabiner, and the shell still read the usual home paths; Git sees the changes in this repo. Commit here. On another machine, clone and `make install-with-backup`.
