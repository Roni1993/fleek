{ config, pkgs, misc, ... }: {
  # Shared user-level customizations.
  programs.bash.initExtra = "nu && exit";
  programs.nushell = {
    configFile.source = ./config.nu;
    shellAliases = {
       ll = "ls -l";
       la = "ls -la";
    };
  };

  programs.starship.settings = {
    format = "[](#9A348E)$os$username[](bg:#DA627D fg:#9A348E)$directory[](fg:#DA627D bg:#FCA17D)$git_branch$git_status[](fg:#FCA17D bg:#86BBD8)$golang$gradle$java$nodejs$rust[](fg:#86BBD8 bg:#06969A)$docker_context[](fg:#06969A bg:#33658A)$time[ ](fg:#33658A)";
  
    username = {
      show_always = true;
      style_user = "bg:#9A348E";
      style_root = "bg:#9A348E";
      format = "[$user ]($style)";
      disabled = false;
    };
  
    os = {
      style = "bg:#9A348E";
      disabled = true;
    };
  
    directory = {
      style = "bg:#DA627D";
      format = "[ $path ]($style)";
      truncation_length = 3;
      truncation_symbol = "…/";
      substitutions = {
        Documents = "󰈙";
        Downloads = "";
        Music = "";
        Pictures = "";
      };
    };
  
    git_branch = {
      symbol = "";
      style = "bg:#FCA17D";
      format = "[ $symbol $branch ]($style)";
    };
  
    git_status = {
      style = "bg:#FCA17D";
      format = "[$all_status$ahead_behind ]($style)";
    };
  
    golang = {
      symbol = "";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
  
    gradle = {
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
  
    java = {
      symbol = "";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
  
    nodejs = {
      symbol = "";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
  
    rust = {
      symbol = "";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
  
    docker_context = {
      symbol = "";
      style = "bg:#06969A";
      format = "[ $symbol $context ]($style)";
    };
  
    time = {
      disabled = false;
      time_format = "%R";
      style = "bg:#33658A";
      format = "[ ♥ $time ]($style)";
    };
  };
  programs.eza = {
    git = true;
    icons = true;
  };
  programs.atuin.flags = [ "--disable-up-arrow"];
  programs.atuin.settings = {
    inline_height = 20;
    enter_accept = true;
    invert = true;
    filter_mode_shell_up_key_binding = "directory";
  };
}
