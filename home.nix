{ config, pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
      
      
    };
  };

  
  # managed by fleek, modify ~/.fleek.yml to change installed packages
  
  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
  home.packages = [
    # user selected packages
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
    pkgs.lunarvim
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
    # Fleek Bling
    pkgs.git
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];
  fonts.fontconfig.enable = true; 
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;
}
