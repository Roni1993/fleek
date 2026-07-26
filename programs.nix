{ pkgs, misc, ... }: {
  # Programs with Home Manager modules that are shared across all profiles.
  # Work- or private-specific program enables live in profiles/work.nix
  # and profiles/private.nix respectively.

  programs.opencode.enable = true;
  # The nixpkgs opencode build (patchelf'd Bun binary) segfaults on WSL2 —
  # https://github.com/NixOS/nixpkgs/issues/520383. Use the official static
  # release binary instead. Bump version + sha256 to upgrade.
  programs.opencode.package = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "opencode";
    version = "1.18.5";
    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
      sha256 = "1qpaq5s8lhp645hqpnmy6jxqhcypx3mmf0jwrckhymfnldbjajnd";
    };
    dontUnpack = true;
    installPhase = ''
      tar -xzf $src
      install -Dm755 opencode $out/bin/opencode
    '';
  };
  programs.dircolors.enable = true;
  programs.nushell.enable = true;
  programs.gh.enable = true;
  programs.zoxide.enable = true;
  programs.starship.enable = true;
  programs.direnv.enable = true;
  programs.carapace.enable = true;
  programs.carapace.enableNushellIntegration = true;
  programs.broot.enable = true;
  programs.atuin.enable = true;
  programs.delta.enable = true;
  programs.delta.enableGitIntegration = true;
  programs.delta.options = {
    navigate = true;
    line-numbers = true;
    side-by-side = true;
  };
}
