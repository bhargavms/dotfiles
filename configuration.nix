{ user, ... }:

{
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
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
      "felixkratz/formulae"
      "hashicorp/tap"
      "jetbrains/utils"
      "nikitabobko/tap"
    ];
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    taps = [
      "derailed/k9s"
      "felixkratz/formulae"
      "hashicorp/tap"
      "jetbrains/utils"
      "nikitabobko/tap"
    ];
    brews = [
      "ansible"
      "cmake"
      "fd"
      "fzf"
      "gh"
      "ghostscript"
      "gitleaks"
      "gnupg"
      "hugo"
      "kubernetes-cli"
      "lefthook"
      "luacheck"
      "pre-commit"
      "tailscale"
      "tree-sitter-cli"
      "xcbeautify"
      "derailed/k9s/k9s"
      "felixkratz/formulae/borders"
      "hashicorp/tap/terraform"
      "jetbrains/utils/kotlin-lsp"
    ];
    casks = [
      "cursor-cli"
      "karabiner-elements"
      "aerospace"
      "wezterm"
    ];
  };
}
