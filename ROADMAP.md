# CachyOS Gaming PC — Progress Tracker

## Legend
- `[x]` Done
- `[ ]` Not started
- `[~]` Blocked

---

## Phase 0 — Decisions (grill-me session) ✓

- [x] Base OS: **CachyOS** (ADR-0001)
- [x] Window manager: **Hyprland**
- [x] Bar/panel: **waybar**
- [x] Notification daemon: **swaync**
- [x] Launcher: **fuzzel**
- [x] Lockscreen: **hyprlock**
- [x] Wallpaper daemon: **ssww**
- [x] Idle manager: **hypridle**
- [x] Output management: **nwg-displays**
- [x] Clipboard: **cliphist + wl-clipboard**
- [x] Theming: **Stylix + runtime toggle script**
- [x] Night-light: **not needed** (theme toggle handles light/dark)
- [x] Terminal: **kitty** (primary) + **ghostty** (secondary)
- [x] Browser: **Firefox** (HM-managed)
- [x] Screenshot: **hyprshot** (grim+slurp wrapper)
- [x] File manager: **Dolphin** (from CachyOS KDE)
- [x] Polkit agent: **hyprpolkitagent**
- [x] Fonts: **JetBrains Mono Nerd Font + Noto**
- [x] Gaming tools: **gamemode + gamescope + mangohud + goverlay + protonup-qt**
- [x] NVIDIA tools: **nvtop + gwe**
- [x] Audio: **pavucontrol**
- [x] Storage: **Both drives** — active games on NVMe, library overflow on HDD
- [x] Nix install method: **Determinate installer**
- [x] Steam Deck UI: **gamescope-session-git** from AUR
- [x] Reproducibility: **bootstrap.sh** handles all system setup post-install

## Phase 1 — OS Installation (manual)

- [x] Download CachyOS ISO (KDE variant) → `cachyos-desktop-linux-260628.iso`
- [x] Flash ISO to USB → `/dev/sdf` (Kingston DataTraveler 3.0, COS_202606)
- [x] Pre-wipe backup staged to `D:\backup-for-cachyos\` (HDD, survives transition):
  - `wsl-keys/` — WSL SSH ed25519 key + sops age key
  - `firefox-profile/` — Firefox profile (404MB)
  - `windows-c/` — Windows C: irreplaceables (8.3MB): `.ssh` RSA key + known_hosts, house-purchase PDFs (Dragonstraat 24 Utrecht), ZMK corne firmware (UF2 + kernel patches), GitHub token + opencode auth
  - DECIDED to skip: other WSL distros (Debian/Ubuntu-20.04) uncommitted work, 168GB LLM models, game saves (Steam Cloud), Unreal/Godot projects
- [ ] Update BIOS (optional, recommended) — v2405 .CAP on USB sdf3 via EZ Flash 3
- [x] Boot from USB, run Calamares installer:
  - Partition NVMe 2TB: `/boot/efi` (1 GB, fat32) + `/` (rest, Btrfs)
  - Leave HDD 4TB untouched (bootstrap handles it)
  - Create user `roni`
- [x] Reboot into KDE session

## Phase 2 — Bootstrap (automated)

- [x] Push fleek changes to GitHub: `git push`
- [x] Open Konsole, run: `curl -sL https://raw.githubusercontent.com/Roni1993/fleek/main/bootstrap.sh | bash`
- [x] Bootstrap handles:
  - System update
  - base-devel + git
  - paru (AUR helper)
  - `cachyos-gaming-meta`
  - `gamescope-session-cachyos` (prebuilt CachyOS repo — NOT AUR, research #15)
  - `hyprpolkitagent` (Arch `extra`)
  - System Hyprland stack (`hyprland hyprlock hypridle hyprshot hyprpicker awww`) — nix builds crash on NVIDIA EGL/GBM
  - GUI apps with own GL renderers (`kitty ghostty discord mangohud`) as system builds
  - HDD mounted read-only at `/mnt/staging` (NTFS untouched, per #6; reformat to `/mnt/games` is #12)
  - NVIDIA driver verification
  - Determinate Nix install
  - Nix flakes enable
  - fleek clone + `nix run .#apply-gaming`
  - Hyprland login session registration + plasmalogin/SDDM autologin
  - All HM-managed tools installed

## Phase 3 — Verification

- [x] **Restore WSL keys from HDD**: `wsl-keys/keys.txt` → `~/.config/sops/age/keys.txt`, SSH keypair → `~/.ssh/` (id_ed25519 + .pub), perms 600. Note: old key is removed from GitHub — rotation pending.
- [x] **Import Firefox profile**: curated copy of `D:\backup-for-cachyos\firefox-profile\` into `~/.mozilla/firefox/roni/` per research #8 (places, favicons, logins+key4 pair, extensions, storage, prefs, cookies, certs).
- [x] Reboot, autologin lands in **Hyprland** (system 0.56.1), login
- [x] Verify WM starts, waybar renders
- [ ] Verify: swaync (notifications), fuzzel (Super+Space), hyprlock (Super+L)
- [ ] Verify: awww wallpaper, cliphist clipboard history
- [ ] Verify: kitty terminal with nushell
- [x] Verify: Firefox with Wayland flags (MOZ_ENABLE_WAYLAND) — profile imported, dual-Firefox conflict resolved
- [ ] Verify: screenshot shortcuts (Print, Super+Shift+S)
- [ ] Verify: hyprpolkitagent (launch a GUI app needing root, e.g. GParted)
- [ ] Verify: Steam starts, Proton works
- [ ] Add `/mnt/games/SteamLibrary` in Steam > Settings > Storage (blocked by #12)
- [ ] Test gamescope per-game: `gamescope -W 2560 -H 1440 -f -- %command%` in Steam launch options
- [ ] Test Steam Game Mode session in plasmalogin/SDDM
- [ ] Run protonup-qt, install GE-Proton
- [ ] Test gamemode: `gamemoderun %command%`
- [ ] Test nvtop + gwe
- [ ] Verify devbox shells rebuild correctly

## Phase 4 — Polish

- [ ] Uncomment Stylix block in `profiles/gaming.nix`, add wallpaper, `nix run .#apply-gaming`
- [ ] Verify GTK/Qt theme consistency
- [ ] Write `~/.local/bin/theme-toggle` for light/dark switching
- [ ] Per-game MangoHud overrides (optional)
- [ ] Backup strategy: snapshots via Timeshift/Snapper, `/nix` backup plan
- [ ] Store `flake.lock` in git

## Phase 5 — Extras (optional)

- [ ] Decky Loader
- [ ] EmuDeck
- [ ] Waydroid
- [ ] Distrobox
- [ ] VirGL/QEMU virtualization
- [ ] VS Code / Cursor

---

## What Bootstrap Handles vs What HM Handles

| Layer | Managed by | How |
|---|---|---|
| Kernel, NVIDIA drivers | `cachyos-gaming-meta` | pacman (bootstrap) |
| Steam, Wine, Proton | `cachyos-gaming-meta` | pacman (bootstrap) |
| Gamescope (CLI + session) | `gamescope-session-cachyos` | prebuilt CachyOS repo (bootstrap) |
| hyprpolkitagent | Arch `extra` | pacman (bootstrap) |
| Hyprland compositor + hyprlock/hypridle/hyprshot/hyprpicker/awww | system (pacman) | nix builds abort on NVIDIA EGL/GBM + Hypr\* ABI guards (bootstrap) |
| kitty, ghostty, discord, mangohud (GL renderers / injectors) | system (pacman) | nix builds share kitty's NVIDIA EGL failure (bootstrap) |
| HDD staging mount (ro) | bootstrap.sh | ntfs-3g + fstab at `/mnt/staging` |
| Hyprland/hypridle/hyprlock/mangohud configs | home-manager | `home.file` (`gaming.nix`) |
| waybar, swaync, nwg-displays | home-manager | `programs.*` / `home.packages` (safe compositor clients) |
| fuzzel (launcher) | system (pacman) | pure Wayland client; config via `~/.config/fuzzel/fuzzel.ini` |
| firefox | home-manager | `programs.firefox` (nix build works; profile imported) |
| gamemode | system (pacman) | installed by bootstrap (not in gaming-meta); config via `~/.config/gamemode.ini` |
| protonup-qt, goverlay, nvtop, gwe, pavucontrol | home-manager | `home.packages` |
| Fonts (JetBrains Mono NF, Noto) | home-manager | `home.packages` |
| Stylix theming | home-manager | `stylix.*` (uncomment to enable) |
| git, ssh, gpg | home-manager | `programs.*` |
| nushell, starship, atuin, etc. | shared modules | `programs.*` |

## Truly Manual Steps (4 total)

1. **BIOS update** — firmware, must be done from BIOS
2. **Download CachyOS ISO** — file download
3. **Flash ISO to USB** — `dd` or similar
4. **Run Calamares installer** — partition NVMe, create user `roni`, set locale

Everything after `curl bootstrap.sh | bash` is automated.
