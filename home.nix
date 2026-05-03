{ config, pkgs, misc, ... }: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  # Packages that have no Home Manager module — everything else is managed
  # via programs.* enables in programs.nix or the profile files.
  home.packages = [
    pkgs.helix
    pkgs.fd
    pkgs.ripgrep
    pkgs.bat
    pkgs.tree
    pkgs.jq
    pkgs.jtc
    pkgs.zip
    pkgs.unzip
    pkgs.wget
    pkgs.curl
    pkgs.neovim
    pkgs.cheat
    pkgs.fzf
    pkgs.lazygit
    pkgs.glow
    pkgs.usbutils
    pkgs.wslu
    pkgs.wsl-open
    pkgs.tilt
    pkgs.kubectl
    pkgs.kubectx
    pkgs.helm
    pkgs.krew
    pkgs.dive
    pkgs.devbox
    pkgs.go
    pkgs.awscli2
  ];

  fonts.fontconfig.enable = true;
  home.stateVersion = "22.11";
  programs.home-manager.enable = true;
}
