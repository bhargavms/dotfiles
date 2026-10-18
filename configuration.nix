{ user, pkgs, ... }:

{
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;

  fonts.packages = [
    pkgs.nerd-fonts._0xproto
  ];

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat              = 2;
      InitialKeyRepeat       = 15;
      _HIHideMenuBar         = true;
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv"; # list view by default
    finder.CreateDesktop = false;
  };

  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
    trust.taps = [
      "derailed/k9s"
      "hashicorp/tap"
      "jetbrains/utils"
    ];
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    taps = [
      "derailed/k9s"
      "hashicorp/tap"
      "jetbrains/utils"
    ];
    brews = [
      "actionlint"
      "ansible"
      "cmake"
      "fd"
      "fzf"
      "gh"
      "ghidra"
      "ghostscript"
      "git-lfs"
      "gitleaks"
      "gnupg"
      "herdr"
      "hugo"
      "kubernetes-cli"
      "lefthook"
      "llvm@22"
      "luacheck"
      "mise"
      "node"
      "pi-coding-agent"
      "pkgconf"
      "pre-commit"
      "rust"
      "rust-analyzer"
      "tailscale"
      "terraform-docs"
      "tesseract"
      "tree"
      "tree-sitter-cli"
      "trivy"
      "xcbeautify"
      "yamllint"
      "derailed/k9s/k9s"
      "hashicorp/tap/terraform"
      "jetbrains/utils/kotlin-lsp"
    ];
    casks = [
      "android-commandlinetools"
      "antigravity"
      "arc"
      "codex"
      "cursor"
      "cursor-cli"
      "jetbrains-toolbox"
      "karabiner-elements"
      "visual-studio-code"
      "wezterm"
      "hopper-disassembler"
    ];
  };
}
