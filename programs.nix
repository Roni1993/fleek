{ pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
  # add your personalized program configuration in ./user.nix   

  # Bling supplied programs

  # User specified programs 
    programs.dircolors.enable = true; 
    programs.eza.enable = true; 
    programs.nushell.enable = true; 
    programs.gh.enable = true; 
    programs.zoxide.enable = true; 
    programs.thefuck.enable = true; 
    programs.starship.enable = true; 
    programs.direnvs.enable = true; 
    programs.carapace.enable = true; 
    programs.broot.enable = true; 
    programs.atuin.enable = true;

}
