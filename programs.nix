{ pkgs, misc, ... }: {
  # Programs with Home Manager modules that are shared across all profiles.
  # Work- or private-specific program enables live in profiles/work.nix
  # and profiles/private.nix respectively.

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
