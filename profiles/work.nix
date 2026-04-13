{ pkgs, lib, ... }: {
  # Work-specific program modules
  programs.opencode.enable = true;
  programs.claude-code.enable = true;

  # GPG + pass for aws-sso SecureStore backend
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableNushellIntegration = true;
    # Cache GPG passphrase for 8 hours so you only enter it once per work session
    defaultCacheTtl = 28800;
    maxCacheTtl = 28800;
    pinentry.package = pkgs.pinentry-curses;
    # Prevent gpg-agent from trying the D-Bus secret-service (unavailable in WSL)
    noAllowExternalCache = true;
    # Allow loopback pinentry so GPG_TTY-based prompts work in the terminal
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  # GPG_TTY must be set so pinentry-curses knows which terminal to use.
  # The HM nushell integration sets $env.GPG_TTY but only works when nushell
  # is started interactively with a real TTY; we make it explicit here as well.
  programs.bash.initExtra = ''
    export GPG_TTY=$(tty)
  '';

  # Patch SecureStore: pass into the existing aws-sso config.
  # We use an activation script rather than xdg.configFile so we don't clobber
  # the rest of the config (SSOConfig, StartUrl, etc.) which is managed by
  # `aws-sso setup wizard` / manual edits.
  home.activation.awsSsoSecureStore =
    let
      yq = "${pkgs.yq-go}/bin/yq";
      cfg = "$HOME/.config/aws-sso/config.yaml";
    in
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      mkdir -p "$(dirname ${cfg})"
      if [ ! -f "${cfg}" ]; then
        echo "SecureStore: pass" > "${cfg}"
      else
        ${yq} -i '.SecureStore = "pass"' "${cfg}"
      fi
    '';

  # Work-specific packages (AWS SSO toolchain + GPG/pass)
  home.packages = [
    pkgs.aws-sso-cli
    pkgs.pass
    pkgs.gnupg
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
