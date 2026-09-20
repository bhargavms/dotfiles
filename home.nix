{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
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
    nodejs
    go
    zulu21
    luarocks
    lua-language-server
    terraform-ls
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
    yamlfix
    beautysh
  ];
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    EDITOR = "nvim";
    JAVA_HOME = pkgs.zulu21.home;
    ANDROID_HOME = "${config.home.homeDirectory}/Library/Android/sdk";
    PYENV_ROOT = "${config.home.homeDirectory}/.pyenv";
    GOPATH = "${config.home.homeDirectory}/go";
    LDFLAGS = "-L${config.home.homeDirectory}/local/lib";
    CPPFLAGS = "-I${config.home.homeDirectory}/local/include";
    PKG_CONFIG_PATH = "${config.home.homeDirectory}/local/lib/pkgconfig";
    LUA_PATH = "${config.home.homeDirectory}/.local/share/lua/5.4.6/?.lua;${config.home.homeDirectory}/.local/share/lua/5.4.6/?/init.lua;";
    LUA_CPATH = "${config.home.homeDirectory}/.local/lib/lua/5.4.6/?.so;";
  };
  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.luarocks/bin"
    "${config.home.homeDirectory}/Library/Android/sdk/platform-tools"
    "${config.home.homeDirectory}/go/bin"
  ];

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

      if [[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]]; then
        export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
      fi
      if [[ -d "$HOME/Library/Python/3.9/bin" ]]; then
        export PATH="$HOME/Library/Python/3.9/bin:$PATH"
      fi

      if command -v rbenv &>/dev/null; then
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
      fi
      if command -v pyenv &>/dev/null; then
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
      fi
    '' + import ./zsh/git-functions.nix;
    envExtra = ''
      export PATH="/etc/profiles/per-user/${config.home.username}/bin''${PATH:+:}$PATH"
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
      [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
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

  # Edit-in-place: the real file stays in the repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/wezterm";
  home.file.".config/karabiner".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/karabiner";
  home.file.".config/aerospace".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/aerospace";
  home.file.".config/gh/config.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/gh/config.yml";
  # File only — herdr keeps sockets/logs/session.json beside config.toml.
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/herdr/config.toml";
}
