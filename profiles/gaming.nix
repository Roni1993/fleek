{ pkgs, lib, inputs, ... }: {
  # ── Gaming profile — CachyOS + Hyprland ────────────────────────
  # Target machine: Intel i5-11400F, NVIDIA RTX 3060 Ti, 32 GB RAM,
  # 2 TB NVMe (OS + active games) + 4 TB HDD (game library overflow).
  #
  # CachyOS provides: kernel (BORE scheduler), NVIDIA drivers,
  # Steam, PipeWire, SDDM, KDE base, gaming-meta package.
  # This profile provides: Hyprland WM + companion tools, theming
  # via Stylix, gaming performance tools, and user-level configs.
  #
  # Apply with: nix run ~/projects/fleek#apply-gaming
  # ─────────────────────────────────────────────────────────────────

  # ── User-level packages (not provided by CachyOS base) ──
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # Gaming tools
    protonup-qt
    goverlay
    nvtopPackages.full
    gwe
    discord

    # Hyprland ecosystem (not HM-moduleable)
    awww
    nwg-displays
    hyprshot                # grim + slurp wrapper

    # Audio
    pavucontrol

    # Clipboard
    wl-clipboard

    # Terminal (ghostty as secondary, kitty handled via programs.*)
    ghostty

    # Fonts
    (nerd-fonts.jetbrains-mono)
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # ── Git ──
  programs.git = {
    enable = true;
    settings = {
      user.name = "Roman";
      user.email = "roman.weintraub@gmail.com";
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

  # ── Hyprland WM ──
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    configType = "hyprlang";

    settings = {
      "$mod" = "SUPER";

      monitor = [
        ",preferred,auto,1"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(cba6f7) rgb(f5c2e7) 45deg";
        "col.inactive_border" = "rgb(45475a)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
          "linear, 0, 0, 1, 1"
        ];
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vrr = 1;
      };

      render.direct_scanout = true;

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master.new_is_master = true;

      gestures.workspace_swipe = true;

      bind = [
        "$mod, RETURN, exec, kitty"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, E, exec, dolphin"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, R, exec, rofi -show drun"
        "$mod, P, pseudo"
        "$mod, S, togglesplit"
        "$mod, SPACE, exec, rofi -show drun"
        "$mod, L, exec, hyprlock"
        "$mod, T, exec, ~/.local/bin/theme-toggle"

        # Screenshots
        ", PRINT, exec, hyprshot -m region"
        "$mod SHIFT, S, exec, hyprshot -m region"
        "$mod, PRINT, exec, hyprshot -m output"

        # Workspace navigation
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspacesilent, 1"
        "$mod SHIFT, 2, movetoworkspacesilent, 2"
        "$mod SHIFT, 3, movetoworkspacesilent, 3"
        "$mod SHIFT, 4, movetoworkspacesilent, 4"
        "$mod SHIFT, 5, movetoworkspacesilent, 5"
        "$mod SHIFT, 6, movetoworkspacesilent, 6"
        "$mod SHIFT, 7, movetoworkspacesilent, 7"
        "$mod SHIFT, 8, movetoworkspacesilent, 8"
        "$mod SHIFT, 9, movetoworkspacesilent, 9"
        "$mod SHIFT, 0, movetoworkspacesilent, 10"

        # Scroll workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindl = [
        # Media keys
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      binde = [
        # Volume control
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
      ];

      exec-once = [
        "waybar"
        "awww-daemon"
        "swaync"
        "hypridle"
        "/usr/lib/hyprpolkitagent/hyprpolkitagent"
        "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "GDK_BACKEND,wayland,x11"
        "NIXOS_OZONE_WL,1"
      ];

      # Per-game window rules
      windowrulev2 = [
        "fullscreen, class:^(.*.exe)$"
        "noblur, class:^(.*.exe)$"
        "nomaximizerequest, class:^(.*.exe)$"
      ];
    };
  };

  # ── Bar ──
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "tray" "pulseaudio" "network" "cpu" "memory" "battery" ];
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{:%A, %B %d, %Y}";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "muted";
          format-icons = {
            default = [ "  " "  " "  " ];
          };
        };
        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "  connected";
          format-disconnected = "  disconnected";
        };
        cpu.format = "  {usage}%";
        memory.format = "  {}%";
      };
    };
    style = ''
      * { font-family: "JetBrainsMono Nerd Font"; font-size: 13px; }
      window#waybar { background: rgba(30, 30, 46, 0.8); color: #cdd6f4; }
      #workspaces button { padding: 0 5px; color: #cdd6f4; }
      #workspaces button.active { color: #cba6f7; }
      #workspaces button.urgent { color: #f38ba8; }
      #clock { padding: 0 10px; }
      #pulseaudio, #network, #cpu, #memory, #tray { padding: 0 8px; }
    '';
  };

  # ── Notifications ──
  services.swaync = {
    enable = true;
    style = ''
      .notification-row { outline: none; }
      .notification { background: rgba(30, 30, 46, 1); color: #cdd6f4; border-radius: 10px; margin: 6px 12px; padding: 10px; }
      .notification-default-action { border-radius: 10px; }
      .notification-default-action:hover { background: rgba(69, 71, 90, 0.5); }
      .notification-content { padding: 6px; }
      .summary { font-weight: bold; color: #cba6f7; }
      .body { color: #a6adc8; }
      .close-button { background: rgba(69, 71, 90, 0.5); border-radius: 50%; margin: 0 4px; }
      .close-button:hover { background: rgba(235, 160, 172, 0.5); }
    '';
  };

  # ── Launcher ──
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = "drun";
    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      display-drun = "  Apps";
      display-run = "  Run";
      drun-display-format = "{name}";
      font = "JetBrainsMono Nerd Font 14";
    };
  };

  # ── Lockscreen ──
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(cba6f7)";
          inner_color = "rgb(30, 30, 46)";
          outer_color = "rgb(69, 71, 90)";
          outline_thickness = 2;
          placeholder_text = "Password...";
        }
      ];
      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo $(date +\"%H:%M\")";
          color = "rgba(205, 214, 244, 1)";
          font_size = 90;
          font_family = "JetBrains Mono Nerd Font";
          position = "0, 40";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # ── Idle management ──
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 600;
          on-timeout = "hyprlock";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  # ── Clipboard ──
  services.cliphist = {
    enable = true;
    systemdTargets = [ "graphical-session.target" ];
    allowImages = true;
  };

  # ── Terminal — kitty (primary) ──
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 12;
    };
    settings = {
      shell = "nu";
      confirm_os_window_close = 0;
      window_padding_width = 8;
      background_opacity = "0.95";
      cursor_shape = "beam";
      cursor_blink_interval = "0.5";
      enable_audio_bell = false;
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
    };
    extraConfig = ''
      # Stylix injects color scheme here at build time
    '';
  };

  # ── Browser — Firefox ──
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    profiles.roni = {
      settings = {
        "browser.disableResetPrompt" = true;
        "browser.download.panel.shown" = true;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.urlbar.suggest.quicksuggest" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "layout.css.devPixelsPerPx" = "1.0";
        "media.ffmpeg.vaapi.enabled" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
    };
  };

  # ── Gaming tools ──
  # programs.gamemode was removed from home-manager; gamemode itself is
  # installed system-wide by cachyos-gaming-meta. Config lives in ~/.config/gamemode.ini.
  home.file.".config/gamemode.ini" = {
    text = ''
      [general]
      renice=10
      desiredgov=performance
      [gpu]
      apply_gpu_optimisations=1
      gpu_device=0
    '';
  };

  programs.mangohud = {
    enable = true;
    settings = {
      fps = true;
      frame_timing = true;
      gpu_stats = true;
      cpu_stats = true;
      ram = true;
      vram = true;
      gpu_temp = true;
      cpu_temp = true;
      engine_version = true;
      gamemode = true;
      config_version = 3;
    };
  };

  # ── Stylix theming ──
  # Stylix module is wired in flake.nix. Uncomment this block and
  # drop a wallpaper.png in ./profiles/ to enable system-wide theming.
  # stylix = {
  #   enable = true;
  #   base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  #   image = ./wallpaper.png;
  #   polarity = "dark";
  #   cursor = {
  #     package = pkgs.bibata-cursors;
  #     name = "Bibata-Modern-Classic";
  #     size = 24;
  #   };
  #   fonts = {
  #     monospace = {
  #       package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
  #       name = "JetBrainsMono Nerd Font";
  #     };
  #     sansSerif = {
  #       package = pkgs.noto-fonts;
  #       name = "Noto Sans";
  #     };
  #     serif = {
  #       package = pkgs.noto-fonts;
  #       name = "Noto Serif";
  #     };
  #   };
  #   targets = {
  #     waybar.enable = true;
  #     hyprland.enable = true;
  #     hyprlock.enable = true;
  #     rofi.enable = true;
  #     kitty.enable = true;
  #     gtk.enable = true;
  #   };
  # };

  # ── Theme toggle script (light ↔ dark) ──
  # Placeholder: a keybind ($mod+T) runs ~/.local/bin/theme-toggle.
  # Write the script in Phase 3 to swap:
  #   - GTK theme (gsettings)
  #   - Qt theme (qt6ct config)
  #   - kitty colors (kitty @ set-colors)
  #   - Hyprland borders (hyprctl keyword)
  #   - waybar CSS (reload)
  #   - Stylix wallpaper polarity
  home.file.".local/bin/theme-toggle" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      echo "theme-toggle: not yet implemented — see gaming.nix"
    '';
  };

  # ── Wallpaper (awww placeholder) ──
  home.file.".local/bin/set-wallpaper" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      wallpaper="''${1:-$HOME/projects/fleek/profiles/wallpaper.png}"
      if [ -f "$wallpaper" ]; then
        awww img "$wallpaper" --transition-type wipe --transition-fps 60
      fi
    '';
  };
}
