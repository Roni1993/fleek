{ lib, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.name = "Roman";
      user.email = "roman.weintraub@gmail.com"; # Update this if your private email should differ.
      alias = {
        pushall = "!git remote | xargs -L1 git push --all";
        graph = "log --decorate --oneline --graph";
        add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
      };
      feature.manyFiles = true;
      init.defaultBranch = "main";
      gpg.format = "ssh";
    };

    signing = {
      key = "";
      signByDefault = builtins.stringLength "" > 0;
    };

    lfs.enable = true;
    ignores = [ ".direnv" "result" ];
  };
}
