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
  # GPU-adjacent apps are system-provided (pacman): nix builds crash on
  # NVIDIA EGL/GBM (nix kitty, nix hyprland) or inject into system
  # processes (mangohud). Only non-GPU CLI/TUI tools stay in nix.
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # Gaming tools (system: discord, mangohud)
    protonup-qt
    goverlay
    nvtopPackages.full
    gwe

    # Hyprland ecosystem (system: hyprland/hyprlock/hyprshot/hyprpicker/awww).
    # nwg-displays is a plain GTK client — safe.
    nwg-displays

    # Audio
    pavucontrol

    # Clipboard
    wl-clipboard

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
      credential.helper = "!gh auth git-credential";
    };
    signing = {
      key = "";
      signByDefault = builtins.stringLength "" > 0;
    };
    lfs.enable = true;
    ignores = [ ".direnv" "result" ];
  };

  # ── Hyprland WM ──
  # The COMPOSITOR is system-provided (pacman `hyprland`). The nix/HM
  # hyprland build aborts on this machine: its bundled mesa looks for
  # /run/opengl-driver/lib/gbm/dri_gbm.so (a NixOS path) which doesn't
  # exist on CachyOS, so the DRM backend fails -> black screen. The
  # system build links against system mesa + NVIDIA stack (same as KDE).
  # Config is managed here via home.file instead of the HM module.
  home.file.".config/hypr/hyprland.conf" = {
    text = ''
      $mod=SUPER
      exec-once=/usr/bin/dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE

      env=XCURSOR_SIZE,24
      env=XDG_CURRENT_DESKTOP,Hyprland
      env=XDG_SESSION_TYPE,wayland
      env=XDG_SESSION_DESKTOP,Hyprland
      env=QT_QPA_PLATFORM,wayland;xcb
      env=QT_WAYLAND_DISABLE_WINDOWDECORATION,1
      env=SDL_VIDEODRIVER,wayland
      env=MOZ_ENABLE_WAYLAND,1
      env=GDK_BACKEND,wayland,x11

      exec-once=waybar
      exec-once=awww-daemon
      exec-once=swaync
      exec-once=hypridle
      # graphical-session.target never activates under system Hyprland
      # (RefuseManualStart), so start HM's graphical-session services directly.
      exec-once=systemctl --user start cliphist.service
      exec-once=/usr/lib/hyprpolkitagent/hyprpolkitagent
      exec-once=systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once=dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      monitor=,preferred,auto,1

      input {
        kb_layout=us
        follow_mouse=1
        touchpad {
          natural_scroll=true
        }
      }

      general {
        gaps_in=5
        gaps_out=10
        border_size=2
        col.active_border=rgb(cba6f7) rgb(f5c2e7) 45deg
        col.inactive_border=rgb(45475a)
        layout=dwindle
      }

      decoration {
        rounding=10
        blur {
          enabled=true
          size=3
          passes=1
          new_optimizations=true
        }
        shadow {
          enabled=true
          range=4
          render_power=3
          color=rgba(1a1a1aee)
        }
      }

      animations {
        enabled=true
        bezier=myBezier, 0.05, 0.9, 0.1, 1.05
        bezier=linear, 0, 0, 1, 1
        animation=windows, 1, 7, myBezier
        animation=windowsOut, 1, 7, default, popin 80%
        animation=border, 1, 10, default
        animation=fade, 1, 7, default
        animation=workspaces, 1, 6, default
      }

      misc {
        disable_hyprland_logo=true
        disable_splash_rendering=true
      }

      render {
        direct_scanout=true
      }

      dwindle {
        preserve_split=true
      }

      master {
        new_on_top=true
      }

      bind=$mod, RETURN, exec, kitty
      bind=$mod, Q, killactive
      bind=$mod, M, exit
      bind=$mod, E, exec, dolphin
      bind=$mod, F, fullscreen
      bind=$mod, V, togglefloating
      bind=$mod, R, exec, rofi -show drun
      bind=$mod, P, pseudo
      bind=$mod, SPACE, exec, rofi -show drun
      bind=$mod, L, exec, hyprlock
      bind=$mod, T, exec, ~/.local/bin/theme-toggle

      bind=, PRINT, exec, hyprshot -m region
      bind=$mod SHIFT, S, exec, hyprshot -m region
      bind=$mod, PRINT, exec, hyprshot -m output

      bind=$mod, 1, workspace, 1
      bind=$mod, 2, workspace, 2
      bind=$mod, 3, workspace, 3
      bind=$mod, 4, workspace, 4
      bind=$mod, 5, workspace, 5
      bind=$mod, 6, workspace, 6
      bind=$mod, 7, workspace, 7
      bind=$mod, 8, workspace, 8
      bind=$mod, 9, workspace, 9
      bind=$mod, 0, workspace, 10

      bind=$mod SHIFT, 1, movetoworkspacesilent, 1
      bind=$mod SHIFT, 2, movetoworkspacesilent, 2
      bind=$mod SHIFT, 3, movetoworkspacesilent, 3
      bind=$mod SHIFT, 4, movetoworkspacesilent, 4
      bind=$mod SHIFT, 5, movetoworkspacesilent, 5
      bind=$mod SHIFT, 6, movetoworkspacesilent, 6
      bind=$mod SHIFT, 7, movetoworkspacesilent, 7
      bind=$mod SHIFT, 8, movetoworkspacesilent, 8
      bind=$mod SHIFT, 9, movetoworkspacesilent, 9
      bind=$mod SHIFT, 0, movetoworkspacesilent, 10

      bind=$mod, mouse_down, workspace, e+1
      bind=$mod, mouse_up, workspace, e-1

      binde=, XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
      binde=, XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
      binde=, XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle

      bindl=, XF86AudioPlay, exec, playerctl play-pause
      bindl=, XF86AudioNext, exec, playerctl next
      bindl=, XF86AudioPrev, exec, playerctl previous

      bindm=$mod, mouse:272, movewindow
      bindm=$mod, mouse:273, resizewindow

      # 0.56 windowrule syntax: `<rule> <match>` (space-separated, no comma).
      # fullscreen works; noblur/nomaximizerequest were removed in 0.56.
      windowrule=fullscreen class:^(.*.exe)$
    '';
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
  # rofi is a plain compositor client (safe in nix). Custom
  # catppuccin-mocha theme matches the Hyprland/waybar palette.
  home.file.".config/rofi/themes/catppuccin-mocha.rasi" = {
    text = ''
      * {
          background-color: transparent;
          text-color: #cdd6f4;
          margin: 0px;
          padding: 0px;
          spacing: 0px;
      }

      window {
          transparency: "real";
          background-color: rgba(30, 30, 46, 0.93);
          border: 2px solid #cba6f7;
          border-radius: 12px;
          width: 620px;
          margin: 80px;
          padding: 12px;
      }

      inputbar {
          background-color: transparent;
          padding: 12px;
      }

      prompt {
          background-color: #313244;
          border-radius: 8px;
          padding: 6px 12px;
          text-color: #f5c2e7;
      }

      entry {
          text-color: #cdd6f4;
          padding: 6px 12px;
          placeholder: "Search";
      }

      listview {
          background-color: transparent;
          padding: 8px 0px;
          lines: 8;
          columns: 1;
      }

      element {
          padding: 10px 14px;
          border-radius: 8px;
          text-color: #cdd6f4;
      }

      element selected {
          background-color: #313244;
          text-color: #cba6f7;
      }

      element-icon {
          size: 0.7em;
          margin: 0px 8px 0px 0px;
      }

      scrollbar {
          width: 6px;
          background-color: transparent;
          handle-color: #45475a;
          border-radius: 3px;
      }

      mainbox {
          background-color: transparent;
      }
    '';
  };
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = "catppuccin-mocha";
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
  # hyprlock is system-provided (pacman); config managed here so the
  # nix build (NVIDIA EGL/GBM) isn't pulled in by home-manager.
  home.file.".config/hypr/hyprlock.conf" = {
    text = ''
      general {
          hide_cursor = true
      }
      background {
          path = screenshot
          blur_passes = 3
          blur_size = 8
      }
      input-field {
          size = 200, 50
          position = 0, -80
          monitor =
          dots_center = true
          fade_on_empty = false
          font_color = rgb(cba6f7)
          inner_color = rgb(30, 30, 46)
          outer_color = rgb(69, 71, 90)
          outline_thickness = 2
          placeholder_text = Password...
      }
      label {
          monitor =
          text = cmd[update:1000] echo $(date +"%H:%M")
          color = rgba(205, 214, 244, 1)
          font_size = 90
          font_family = JetBrains Mono Nerd Font
          position = 0, 40
          halign = center
          valign = center
      }
    '';
  };

  # ── Idle management ──
  # hypridle is system-provided (pacman) and started via hyprland's
  # exec-once. Config lives at ~/.config/hypr/hypridle.conf.
  home.file.".config/hypr/hypridle.conf" = {
    text = ''
      general {
          after_sleep_cmd = hyprctl dispatch dpms on
          ignore_dbus_inhibit = false
      }
      listener {
          timeout = 300
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
      }
      listener {
          timeout = 600
          on-timeout = hyprlock
      }
      listener {
          timeout = 900
          on-timeout = systemctl suspend
      }
    '';
  };

  # ── Clipboard ──
  services.cliphist = {
    enable = true;
    systemdTargets = [ "graphical-session.target" ];
    allowImages = true;
  };

  # ── Terminal — kitty (primary) ──
  # Using system kitty (pacman) instead of nix kitty — nix kitty's bundled
  # libglvnd crashes with NVIDIA EGL (segfault on display init).
  # Config is managed via home.file; kitty itself stays system-provided.
  home.file.".config/kitty/kitty.conf" = {
    text = ''
      font_family JetBrains Mono Nerd Font
      font_size 12
      shell nu
      shell_integration no-rc
      confirm_os_window_close 0
      window_padding_width 8
      background_opacity 0.95
      cursor_shape beam
      cursor_blink_interval 0.5
      enable_audio_bell no
      tab_bar_edge top
      tab_bar_style powerline
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
  # programs.gamemode was removed from home-manager; the gamemode package
  # is installed by bootstrap.sh (cachyos-gaming-meta does NOT pull it in).
  # Config lives in ~/.config/gamemode.ini.
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

  # ── MangoHud overlay ──
  # mangohud is system-provided (pacman) — the nix build injects into
  # system Steam/game processes with its own libs (mismatch risk).
  # Config is managed via home.file.
  home.file.".config/mangohud/MangoHud.conf" = {
    text = ''
      fps=1
      frame_timing=1
      gpu_stats=1
      cpu_stats=1
      ram=1
      vram=1
      gpu_temp=1
      cpu_temp=1
      engine_version=1
      gamemode=1
      config_version=3
    '';
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
