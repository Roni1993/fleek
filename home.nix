{ config, pkgs, misc, ... }: {
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
      
      
    };
  };

  
  home.packages = [
    pkgs.helix
    pkgs.fd
    pkgs.ripgrep
    pkgs.bat
    pkgs.tree
    pkgs.jq
    pkgs.jtc
    pkgs.gh
    pkgs.zip
    pkgs.unzip
    pkgs.wget
    pkgs.direnv
    pkgs.curl
    pkgs.neovim
    pkgs.nushell
    pkgs.starship
    pkgs.carapace
    pkgs.cheat
    pkgs.fzf
    pkgs.zoxide
    pkgs.atuin
    pkgs.broot
    pkgs.tilt
    pkgs.kubectl
    pkgs.kubectx
    pkgs.helm
    pkgs.krew
    pkgs.dive
    pkgs.lazygit
    pkgs.wslu
    pkgs.wsl-open
    pkgs.devbox
    pkgs.aider-chat
    pkgs.opencode
    pkgs.delta
    pkgs.glow
    pkgs.usbutils
    pkgs.git
  ];
  fonts.fontconfig.enable = true; 
  home.stateVersion = "22.11";
  programs.home-manager.enable = true;
}
