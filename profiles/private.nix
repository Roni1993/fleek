{ lib, ... }: {
  # Install pi coding agent (npm) and graphify (pip) imperatively
  home.activation.installPiAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! command -v pi &>/dev/null; then
      echo "Installing @mariozechner/pi-coding-agent..."
      npm install -g @mariozechner/pi-coding-agent
    fi
  '';

  home.activation.installGraphify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! command -v graphify &>/dev/null; then
      echo "Installing graphifyy..."
      pip install --user graphifyy
    fi
  '';

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

