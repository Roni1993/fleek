{ pkgs, misc, ... }: {
  programs.dircolors.enable = true;
  programs.nushell.enable = true;
  programs.opencode.enable = true;
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
