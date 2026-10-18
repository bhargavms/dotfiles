# Dotfiles

Personal macOS setup: nix-darwin, home-manager, and nix-homebrew. The flake host is `mac`.

Clone this repo anywhere; `./rebuild.sh` points `~/.dotfiles` at it and applies the flake. home-manager generates `~/.zshrc` (Starship, not Oh My Zsh). Aliases live in `zsh/aliases.nix`; Git helper functions live in `zsh/git-functions.nix`. XDG apps live under `config/` and map 1:1 onto `~/.config` as out-of-store symlinks.

## Prerequisites

- Apple Silicon Mac with an administrator account; the current configuration targets the username `bhargav`.
- Xcode Command Line Tools (includes Git): run `xcode-select --install` and finish the installer.
- [Determinate Nix](https://docs.determinate.systems/determinate-nix/) — after installation, open a new terminal and verify `nix --version`.

Neither nix-darwin nor Homebrew needs to be installed beforehand; `./rebuild.sh` bootstraps them.

The supported target is Apple Silicon macOS (`aarch64-darwin`) with Homebrew at `/opt/homebrew`. After cloning, compare `id -un` with the `user` value in `flake.nix`; if the new Mac's short account name differs, change that one value **before the first rebuild**. Managed home/config paths derive from it.

## Install

```bash
git clone https://github.com/bhargavms/dotfiles.git
cd dotfiles
# If `id -un` is not bhargav, update `user` in flake.nix before rebuilding.
./rebuild.sh
exec zsh -l
```

The HTTPS clone works without an SSH key. Configure GitHub authentication separately when you need to push changes.

`./rebuild.sh` checks for Nix, creates `~/.dotfiles`, and runs the configuration's `darwin-rebuild` package through `nix run`, using the inputs pinned in `flake.lock`. The same command handles first installation and later rebuilds without requiring `darwin-rebuild` on `PATH`. It requests `sudo` to apply the system configuration, installs Homebrew and the declared packages, and links the configs below. It does not update the lockfile; change inputs explicitly with `nix flake update` when intended.

## What Nix owns

| File | Role |
|------|------|
| `flake.nix` | Inputs (nixpkgs 26.05, nix-darwin, home-manager, nix-homebrew, Oh My Pi) and `darwinConfigurations.mac` |
| `configuration.nix` | macOS defaults, [0xProto Nerd Font](https://github.com/ryanoasis/nerd-fonts), Homebrew taps/formulae/casks (`cleanup = uninstall`) — including `mise`, `node`, `rust`, `rust-analyzer`, `pi-coding-agent` |
| `home.nix` | User packages (nvim, Go, Java, LSPs, formatters), `programs.git`, `programs.omp`, `programs.zsh`, Starship, config links |
| `packages/go-tools.nix` | Custom Go helpers with pinned source versions and source/dependency hashes |
| `scripts/private_settings.py` | Password-encrypted private settings backup and review-only restore, installed as `dotfiles-private-settings` |
| `zsh/aliases.nix` | `shellAliases` (git, gradle, codex, …) |
| `zsh/git-functions.nix` | `initContent` helpers: `git_main_branch`, `gpur`, `gCleanB`, `gsquash` |
| `.pre-commit-config.yaml` | One hook owner (`pre-commit`), formatting checks, and staged-secret detection; installed/refreshed automatically after a successful rebuild |

Neovim **config** is not in this repo (see below). The `neovim` package and language servers/formatters are.

The Homebrew inventory is strict: rebuilding normally uninstalls Homebrew packages that are not declared in `configuration.nix`. It does not use cask `zap` to deliberately remove additional preferences/data. Declare any manually installed Homebrew packages you want to retain before rebuilding; normal uninstall is not a substitute for a backup.

Homebrew owns the default Node.js runtime and npm; there is no separate Node.js entry in `home.packages`. Outside projects with mise tool selections, Node falls back to Homebrew. `command -v node` may show a mise shim that delegates to the Homebrew runtime. Other Nix-managed tools may retain their own Node dependencies internally.

## Development tools

Homebrew declares the development CLI inventory, including actionlint, Git LFS, LLVM 22, pkgconf, terraform-docs, Tesseract, tree, Trivy, and yamllint. Stable Nix supplies TFLint, Lua 5.4's Busted test runner, `normalizer` (charset-normalizer), and `pymupdf` with their managed interpreters/dependencies, alongside the existing Go tools, language servers, and formatters.

`packages/go-tools.nix` supplies go-enum, gojsonstruct, gomvp, and json-to-struct at pinned versions. These custom packages may compile Go code on the first build; subsequent builds reuse the Nix store while their inputs are unchanged. Upgrades require updating the version, source hash, and dependency hash together and checking the resulting tools. `gomvp` requires a clean Git working tree.

`fillswitch` is intentionally excluded: the installed source version assumes a legacy GOPATH layout and crashes on generic type parameters with the current Go toolchain. Its existing local binary is not deleted by this configuration.

Home Manager supplies Git LFS filters. To initialize a repository's LFS pre-push hook without rewriting managed global settings, run this from that repository:

```bash
git lfs install --local
```

Project libraries and dependency lockfiles belong in their respective project repositories; old pip, LuaRocks, Go, and version-manager cache directories are not substitutes for package declarations.

## Project runtime versions

`flake.lock` pins Nix inputs and packages, including Go and Java. Homebrew-managed software follows current releases rather than exact versions from that lockfile; existing packages are not automatically upgraded by rebuilds. Use `brew outdated` to inspect updates and `brew upgrade` when you intend to update them.

Exact Node.js, Python, Rust, and Terraform versions belong in each project's `mise.toml` and `mise.lock`, not in global tool selections. Homebrew installs [mise](https://mise.jdx.dev/getting-started.html), and Zsh activates the project's tools on directory changes. `config/mise/config.toml` enables exact pins (`pin = true`) and automatic lockfile creation (`lockfile = true`) without selecting any global runtime versions.

For a new project needing all four tools, this example selects current releases and records exact versions. Choose versions compatible with that project's requirements, and include only the tools it needs:

```bash
mise use --pin node@lts python@3 rust@latest terraform@latest
mise lock
```

Commit `mise.toml` and `mise.lock` in that project's repository. On the next Mac, review the project's mise config/tasks before trusting it, then restore its locked tools:

```bash
mise trust
mise install --locked
```

Check the selected tools with `mise ls --current`; use `mise exec -- <command>` in scripts/CI that do not load interactive Zsh. Keep the project's application dependency lockfiles as well. Mise's [Rust backend](https://mise.jdx.dev/lang/rust.html) uses rustup for project toolchains; the Homebrew Rust installation remains the machine-wide fallback.

Mise is the only automatically initialized runtime version manager. Zsh no longer initializes pyenv/rbenv or adds the old Python 3.9/LuaRocks command paths, and obsolete Lua 5.4.6 and `~/local` compiler/library variables are not exported globally. Set project-specific paths and build flags in that project's environment instead.

Existing `.pyenv`, `.nvm`, `.config/tfenv`, `.rustup`, `.cargo`, and LuaRocks directories are left untouched, but are not restore inputs. Recreate project runtimes from their committed mise files; rustup remains mise's Rust backend rather than a separate global startup hook. After applying this cleanup, start a fresh terminal session (quit/reopen WezTerm if needed) rather than inheriting old exported variables through `exec zsh`.

## Desktop applications

Homebrew installs Arc, Cursor desktop, Antigravity, Visual Studio Code, and JetBrains Toolbox. `cursor-cli` is installed separately from the Cursor editor.

After rebuilding, open JetBrains Toolbox, sign in, and install the IDEs you use. In each IDE, install the IdeaVim plugin from Plugins and restart the IDE; this repo links `~/.ideavimrc` but does not install the plugin or manage IDE licenses. Use JetBrains settings sync for additional IDE preferences and plugins if desired. Browser/editor sign-ins and local application state are not restored by installing their casks.

## Android SDK and emulator

Homebrew installs `android-commandlinetools`; the existing Nix-managed Java 21 supplies `JAVA_HOME`. Home Manager writes `~/.androidrc` so the [Android CLI](https://developer.android.com/tools/agents/android-cli) uses `ANDROID_HOME` (`~/Library/Android/sdk`), not Homebrew's separate default SDK directory. Platform tools and the emulator are on `PATH`; the old SDK-local command-line tools are no longer prepended.

After rebuilding and opening a new login shell, review and accept the required SDK licenses interactively. Google's standalone license workflow still uses the bundled `sdkmanager`; package management below uses the newer `android sdk` commands.

```bash
/opt/homebrew/bin/sdkmanager --sdk_root="$ANDROID_HOME" --licenses
```

Restore the stable SDK baseline, including the ARM64 Google Play emulator image and NDK r27c:

```bash
android sdk install --no-downgrade \
  "build-tools/34.0.0" \
  "build-tools/35.0.1" \
  "build-tools/36.0.0" \
  "cmake/3.22.1" \
  "cmake/3.31.6" \
  "emulator" \
  "ndk/27.2.12479018" \
  "platform-tools" \
  "platforms/android-34" \
  "platforms/android-35" \
  "sources/android-35" \
  "system-images/android-36/google_apis_playstore/arm64-v8a"
```

This does not opt into beta/canary packages or restore the old incomplete NDK 25 directory. SDK package IDs are recorded above; emulator/platform-tool revisions follow Google's stable releases. Projects must still declare their SDK/NDK requirements. Existing SDK files are not deleted.

Inspect the result with `android sdk list`. To create a virtual device separately, inspect profiles with `android emulator create --list-profiles`, then pass the chosen profile to `android emulator create`. `android emulator list` shows the available devices. Device profiles can request additional SDK images. Existing AVD userdata and Android signing keystores are private state, not restored SDK packages.

## Oh My Pi

[Oh My Pi](https://github.com/can1357/oh-my-pi) (`omp`) is installed through its official Nix flake and Home Manager module. The release is selected in `flake.nix` and its source and build dependencies are pinned in `flake.lock`.

The first build downloads the pinned toolchains and compiles native code, which can take several minutes. Subsequent rebuilds reuse the package from the Nix store while its inputs are unchanged.

```bash
./rebuild.sh
exec zsh -l
omp --version
omp setup
```

Run `omp` in a project to start a session; `/login` connects a provider account. On another Apple Silicon Mac, follow the [installation steps](#install) to install the pinned version, then configure authentication there.

Preferences and agent state stay writable under `~/.omp/agent`. This setup leaves runtime preferences out of public Nix configuration; restore them through the [private settings workflow](#private-preferences-and-restore), and configure provider authentication separately. Keep credentials out of Nix and Git.

To upgrade, change the release tag in `inputs.omp.url`, then run:

```bash
nix flake update omp
./rebuild.sh
```

The existing Homebrew `pi-coding-agent` provides the separate `pi` command; Oh My Pi uses `omp`.

## What gets linked

home-manager (`mkOutOfStoreSymlink`) points these at the repo:

| Source | Target |
|--------|--------|
| `ideavimrc` | `~/.ideavimrc` |
| `config/wezterm/` | `~/.config/wezterm` |
| `config/karabiner/` | `~/.config/karabiner` |
| `config/mise/config.toml` | `~/.config/mise/config.toml` |
| `config/gh/config.yml` | `~/.config/gh/config.yml` |
| `config/herdr/config.toml` | `~/.config/herdr/config.toml` |

Edit these sources in the repo; the listed targets are live symlinks. `~/.config` itself remains a directory, not a link to this repository.

## Private preferences and restore

This public repo owns portable defaults, not personal identities, work endpoints, or private instructions. Restore only the private paths below after applying the dotfiles; do not overwrite the managed shell, Git defaults, or app config links with an old home-directory copy.

### Git identity and work overrides

Home Manager writes Git/LFS defaults to `~/.config/git/config`. Your private `~/.gitconfig` takes precedence and is left untouched. Back it up privately along with any files referenced by its `include`/`includeIf` entries. Signing identities, keys, and credentials remain local.

If you are not restoring an existing identity file, create/edit it explicitly rather than asking Git to write to the managed XDG config:

```bash
git config --file "$HOME/.gitconfig" --edit
```

Set your own `user.name` and `user.email` there. Do not put credentials into the public configuration.

### Neovim working configuration

Neovim's configuration lives in the separate [`my-nvim`](https://github.com/bhargavms/my-nvim) repository. Before moving, check for local changes and identify the real working tree:

```bash
git -C "$HOME/.config/nvim" status --short
git -C "$HOME/.config/nvim" rev-parse --show-toplevel
```

Push changes you intend to publish in that repository, or privately back up the entire working tree, including untracked files. Saving only the `~/.config/nvim` symlink is insufficient. Restore the tree's contents under the new account; do not reuse an absolute symlink pointing into the old home directory.

On a new Mac without a privately restored Neovim configuration:

```bash
mkdir -p "$HOME/.config"
git clone https://github.com/bhargavms/my-nvim.git "$HOME/.config/nvim"
```

The clone restores committed configuration only; it cannot recover unpublished local changes.

### Editor and agent preferences

Use each editor's settings sync/profile export where available. Keep a private encrypted backup of the following paths, where present:

| Scope | Private restore inputs |
|-------|------------------------|
| VS Code, Cursor, Antigravity | Under `~/Library/Application Support/{Code,Cursor,Antigravity}/User/`: `settings.json`, `keybindings.json`, snippets, and per-profile preferences. Use settings sync or an extension/profile export to restore installed extensions. |
| Agent configuration | `~/.codex/config.toml` and `~/.omp/agent/config.yml`; these may contain work-specific MCP endpoints or environment settings. The GrowthBook Codex aliases require the private MCP configuration and separately provisioned credentials. |
| Custom skills/instructions | `~/.agents/skills`, custom skills under `~/.codex/skills`, and your custom agent instruction files. Save the real contents of symlink targets; let tools recreate generated system-skill directories. |

Do not copy entire application directories or restore machine-bound auth/session databases as preference files. Credentials and key material use the separate [manual recovery checklist](#credentials-and-macos-recovery).

The local code-signing helper (`~/.local/bin/rituel-sign`) stays private. The bundle below includes its source, but not its signing certificate/private key.

Caches, histories, AVD userdata, and unrelated app state are not part of the declarative restore. Karabiner backups and WezTerm `workspace-states/` are gitignored if they appear beside tracked configs.

## Encrypted private settings bundle

After activating this configuration, `dotfiles-private-settings` uses stable Nix Python/Git and Homebrew GnuPG. Before activation, an installed Python 3.12+ can run the same tool with `python3 scripts/private_settings.py` in place of `dotfiles-private-settings`.

Close editors/agents or pause edits while capturing; this is a file backup, not a live filesystem snapshot. Create the bundle on the Mac's local disk, **outside any Git working tree**:

```bash
BACKUP="$HOME/private-settings-$(date +%Y%m%d-%H%M%S).gpg"
dotfiles-private-settings backup "$BACKUP"

# Recovery drill now, or after transferring the bundle to the new Mac:
dotfiles-private-settings restore "$BACKUP" "$HOME/private-settings-review"
```

GnuPG prompts locally for a password. Use a long random passphrase saved in a password manager accessible without the old laptop. Copy only the encrypted `.gpg` file to separate storage; do not keep its password beside it or commit the bundle.

The bundle captures the private paths above, existing Git include files under your home directory (including inactive `includeIf` branches), and the real contents of symlink targets. Generated Codex `.system` skills are excluded. Missing optional Git includes are ignored as Git does; existing includes outside your home require a separate private backup.

Installed extension IDs are exported from each editor's local inventory into `.dotfiles-private/extensions/` inside the bundle. Reinstall them through that editor's extension interface; this does not preserve extension binaries or guarantee marketplace availability. Per-profile preference files are included, but editor sync/profile exports remain the way to recreate profile names and selections.

Restore authenticates the encrypted data before extraction, rejects traversal/link entries, refuses existing destinations, and publishes only a new private review directory. It never merges into your active home. Treat the review directory as secret: configuration files can contain inline credentials, which are encrypted, not redacted. No standalone auth stores, SSH/GPG keys, certificates, or Android keystores are automatically collected.

Inspect `.dotfiles-private/manifest.json` privately. After applying the dotfiles on the new Mac, copy only the intended private files into their corresponding home-relative locations, preserving the helper's executable permission. Do not replace managed config links. Review old absolute paths in Git includes, MCP configuration, and signing scripts if your account or checkout locations changed. Reinstall per-repository hooks rather than trusting old interpreter paths.

Before retiring the old Mac, perform the restore drill, open the restored preferences, confirm the Neovim working tree includes unpublished changes, and confirm the signing helper's source is present. Delete the plaintext review directory when finished. Temporary plaintext staging is removed after restore, but secure physical erasure is not promised on APFS/SSDs; keep FileVault enabled.

## Credentials and macOS recovery

These require deliberate private recovery or fresh enrollment; the settings bundle is not a keychain or account backup.

| Recovery item | Before retiring the old Mac / on the new Mac |
|---------------|---------------------------------------------|
| Password manager, Apple Account, MFA | Confirm access from another trusted device; retain recovery codes/security keys outside this laptop. |
| FileVault | Keep the [recovery key](https://support.apple.com/guide/mac-help/filevault-recovery-key-mh35880/mac) somewhere other than the encrypted startup disk; enable FileVault on the new Mac. |
| SSH and GPG identities | Recover keys through your established encrypted key backup or hardware token, or create replacement keys and re-enroll them with services. Never put private keys or passphrases in this repo. |
| Code-signing identity | In Keychain Access, select the certificate **and private key**, then [File → Export Items](https://support.apple.com/guide/keychain-access/import-and-export-keychain-items-kyca35961/mac); use password-protected PKCS#12 (`.p12`) where supported. Import privately on the new Mac. Non-exportable/hardware-bound keys require replacement or re-enrollment. Test the private signing helper against a disposable copy before relying on it. |
| Android signing | Separately back up release/upload keystores and their passwords; retain a debug keystore too if a service depends on its registered fingerprint. Restore only to the project's intended private location. |
| GitHub CLI | After restoring local Git identity, run `gh auth login`; do not transplant `~/.config/gh/hosts.yml` as the default recovery method. |
| Coding agents | Use `codex login`, `omp setup`/`/login`, and Pi's `/login` flow as appropriate; recover API keys through your secret manager, not copied session stores. |
| Infrastructure/MCP credentials | Re-provision Terraform credentials, `TFE_TOKEN`, and any work-specific MCP/environment secrets privately; restore approved local secret files from your secret manager. Do not put them into Nix expressions/store paths. |
| App accounts/licenses | Confirm recovery access for JetBrains, Hopper, browsers, and other licensed/synced applications; sign in again on the new Mac. |
| macOS permissions | Approve Karabiner's requested input-monitoring/driver permissions and any app-specific Accessibility, automation, developer-tools, or disk access through System Settings. Do not copy TCC databases or disable SIP/Gatekeeper to bypass prompts. |

A successful settings restore does not verify account/key backups or possession of a FileVault recovery key. Actual private backup creation, password retention, key export, account recovery, and GUI permission approvals remain human steps.

## Commit protection

Run `./rebuild.sh` as your normal user, not through `sudo`. It elevates only the system switch, then installs this clone's pre-commit hook and environments as your user, even when invoked from another directory. The installer replaces older pre-commit launchers; there is no separate `.githooks` implementation.

Gitleaks scans the **staged Git diff**, redacts findings, and blocks the commit when it detects a secret. The hook calls the Apple Silicon Homebrew binary explicitly, avoiding dependence on an editor's inherited PATH. The general checks use the pinned [pre-commit-hooks v6.0.0 release](https://github.com/pre-commit/pre-commit-hooks/releases/tag/v6.0.0).

If hook installation fails after the system switch, the system may already be updated. Fix the reported problem and refresh hooks from this clone without rebuilding again:

```bash
pre-commit install --install-hooks --overwrite
pre-commit run --all-files
```

The second command runs formatting/structure checks over tracked files; its Gitleaks hook still scans staged changes only. Stage intended changes before relying on that scan. Local hooks can be bypassed and are not server-side enforcement or proof that every secret format will be detected. If a real credential is committed/pushed, revoke or rotate it; deleting the text is insufficient.

For the private bundle's security regressions, use Python 3.12+:

```bash
python3 -B -m unittest discover -s tests -v
```

## Layout

```
.
├── flake.nix
├── flake.lock
├── configuration.nix
├── home.nix
├── packages/
│   └── go-tools.nix
├── rebuild.sh
├── .pre-commit-config.yaml
├── scripts/private_settings.py
├── tests/test_private_settings.py
├── zsh/
│   ├── aliases.nix
│   └── git-functions.nix
├── ideavimrc
└── config/
    ├── wezterm/
    ├── karabiner/karabiner.json
    ├── mise/config.toml
    ├── herdr/config.toml
    └── gh/config.yml
```

## Day to day

- **Shell aliases** — edit `zsh/aliases.nix`.
- **Git functions** — edit `zsh/git-functions.nix`.
- **Prompt / packages / env** — edit `home.nix`.
- **Homebrew / macOS defaults / fonts** — edit `configuration.nix` (Rust, Pi, CLI tools that have formulae).
- **WezTerm, Karabiner, IdeaVim** — edit in this repo (or via the live `~/.config` / `~/.ideavimrc` links).

Apply Nix changes with `./rebuild.sh`, then `exec zsh -l`. On another machine: clone, then `./rebuild.sh`.
