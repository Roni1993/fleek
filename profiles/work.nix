{ pkgs, ... }: {
  # Work-specific program modules
  programs.opencode.enable = true;
  programs.claude-code.enable = true;

  # Work-specific packages (k8s / devops toolchain)
  home.packages = [
    pkgs.tilt
    pkgs.kubectl
    pkgs.kubectx
    pkgs.helm
    pkgs.krew
    pkgs.dive
    pkgs.devbox
    pkgs.aider-chat
    pkgs.aws-sso-cli
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "Roman Weintraub";
      user.email = "roman.weintraub@gmail.com"; # Update this to your work email.
      alias = {
        pushall = "!git remote | xargs -L1 git push --all";
        graph = "log --decorate --oneline --graph";
        add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
      };
      feature.manyFiles = true;
      init.defaultBranch = "main";
      gpg.format = "ssh";
      credentials.helper = "cache --timeout 86400";
    };

    signing = {
      key = "";
      signByDefault = builtins.stringLength "" > 0;
    };

    lfs.enable = true;
    ignores = [ ".direnv" "result" ];
  };
}
