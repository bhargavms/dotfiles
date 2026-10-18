{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  goTools = import ./packages/go-tools.nix {
    inherit (pkgs) buildGoModule fetchFromGitHub lib;
  };
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    ripgrep
    jq
    lazygit
    neovim
    go
    zulu21
    luarocks
    lua54Packages.busted
    lua-language-server
    terraform-ls
    tflint
    yaml-language-server
    kotlin-language-server
    graphql-language-service-cli
    jdt-language-server
    sqls
    gopls
    delve
    golangci-lint
    golines
    gotools
    gofumpt
    richgo
    ginkgo
    impl
    govulncheck
    gotestsum
    mockgen
    iferr
    gotests
    gomodifytags
    stylua
    ktlint
    ktfmt
    prettierd
    prettier
    clang-tools
    yamlfmt
    beautysh
    python3Packages.charset-normalizer
    python3Packages.pymupdf
    (writeShellApplication {
      name = "dotfiles-private-settings";
      runtimeInputs = [ python3 git ];
      text = ''
        exec python3 "${./scripts/private_settings.py}" "$@"
      '';
    })
  ] ++ builtins.attrValues goTools;
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    EDITOR = "nvim";
    JAVA_HOME = pkgs.zulu21.home;
    ANDROID_HOME = "${config.home.homeDirectory}/Library/Android/sdk";
    GOPATH = "${config.home.homeDirectory}/go";
  };
  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.sessionVariables.ANDROID_HOME}/platform-tools"
    "${config.home.sessionVariables.ANDROID_HOME}/emulator"
    "${config.home.homeDirectory}/go/bin"
  ];

  programs.git = {
    enable = true;
    lfs = {
      enable = true;
      package = null; # Homebrew owns git-lfs.
    };
  };

  programs.omp.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      bindkey '^f' autosuggest-accept

      if [[ -n $SSH_CONNECTION ]]; then
        export EDITOR='vim'
      fi

      discover_gcloud_sdk() {
        local possible_paths=(
          "$HOME/google-cloud-sdk"
          "/usr/local/share/google-cloud-sdk"
          "/opt/google-cloud-sdk"
          "/usr/share/google-cloud-sdk"
          "/Applications/google-cloud-sdk"
          "$HOME/.local/share/google-cloud-sdk"
          "$HOME/Library/google-cloud-sdk"
        )
        local path
        for path in "''${possible_paths[@]}"; do
          if [[ -d "$path" && -f "$path/bin/gcloud" ]]; then
            echo "$path"
            return 0
          fi
        done
        local gcloud_path
        gcloud_path=$(command -v gcloud 2>/dev/null) || return 1
        local sdk_path="''${gcloud_path%/*}"
        sdk_path="''${sdk_path%/*}"
        if [[ -d "$sdk_path" && -f "$sdk_path/bin/gcloud" ]]; then
          echo "$sdk_path"
          return 0
        fi
        return 1
      }
      export CLOUDSDK_HOME=$(discover_gcloud_sdk)
      if [[ -n "$CLOUDSDK_HOME" && -d "$CLOUDSDK_HOME/bin" ]]; then
        export PATH="$CLOUDSDK_HOME/bin:$PATH"
      fi

      if command -v mise &>/dev/null; then
        eval "$(mise activate zsh)"
      fi
    '' + import ./zsh/git-functions.nix;
    envExtra = ''
      export PATH="/etc/profiles/per-user/${config.home.username}/bin''${PATH:+:}$PATH"
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    '';
    shellAliases = import ./zsh/aliases.nix;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  home.file.".ideavimrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ideavimrc";
  home.file.".androidrc".text =
    "--sdk=${config.home.sessionVariables.ANDROID_HOME}\n";

  # Edit-in-place: the real file stays in the repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/wezterm";
  home.file.".config/karabiner".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/karabiner";
  home.file.".config/gh/config.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/gh/config.yml";
  home.file.".config/mise/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/mise/config.toml";
  # File only — herdr keeps sockets/logs/session.json beside config.toml.
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/herdr/config.toml";
}
