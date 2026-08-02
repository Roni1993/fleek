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
- [x] Launcher: **rofi-wayland**
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

- [ ] Update BIOS (ASUS ROG STRIX B560-I, currently v0503, Feb 2021)
- [x] Download CachyOS ISO (KDE variant) → `cachyos-desktop-linux-260628.iso`
- [x] Flash ISO to USB → `/dev/sdf` (Kingston DataTraveler 3.0, COS_202606)
- [ ] Boot from USB, run Calamares installer:
  - Partition NVMe 2TB: `/boot/efi` (1 GB, fat32) + `/` (rest, Btrfs)
  - Leave HDD 4TB untouched (bootstrap handles it)
  - Create user `roni`
- [ ] Reboot into KDE session

## Phase 2 — Bootstrap (automated)

- [ ] Push fleek changes to GitHub (from current WSL machine): `git push`
- [ ] Open Konsole, run: `curl -sL https://raw.githubusercontent.com/Roni1993/fleek/main/bootstrap.sh | bash`
- [ ] Bootstrap handles:
  - System update
  - base-devel + git
  - paru (AUR helper)
  - `cachyos-gaming-meta`
  - `gamescope-session-git` (AUR)
  - `hyprpolkitagent` (AUR)
  - NVIDIA driver verification
  - HDD partitioning + fstab + mount at `/mnt/games`
  - Determinate Nix install
  - Nix flakes enable
  - fleek clone + `nix run .#apply-gaming`
  - All HM-managed tools installed

## Phase 3 — Verification

- [ ] **Restore WSL keys from HDD**: Copy `D:\backup-for-cachyos\wsl-keys\keys.txt` → `~/.config/sops/age/keys.txt`, and the SSH keypair to `~/.ssh/`. Set permissions: `chmod 600 ~/.ssh/id_ed25519`. Verify with `ssh -T git@github.com`.
- [ ] **Import Firefox profile**: Copy `D:\backup-for-cachyos\firefox-profile\` contents into `~/.mozilla/firefox/<hm-profile>/`. The HM-managed Firefox profile directory is at: `ls ~/.mozilla/firefox/`. Replace placeholder profile contents, or update `profiles.ini` to point at a subdirectory with the backed-up data. Key files: `places.sqlite` (bookmarks), `logins.json` + `key4.db` (saved passwords), `extensions/` (addons).
- [ ] Reboot, select **Hyprland** in SDDM, login
- [ ] Verify WM starts, waybar renders
- [ ] Verify: swaync (notifications), rofi (Super+Space), hyprlock (Super+L)
- [ ] Verify: swww wallpaper, cliphist clipboard history
- [ ] Verify: kitty terminal with nushell
- [ ] Verify: Firefox with Wayland flags
- [ ] Verify: screenshot shortcuts (Print, Super+Shift+S)
- [ ] Verify: hyprpolkitagent (launch a GUI app needing root, e.g. GParted)
- [ ] Verify: Steam starts, Proton works
- [ ] Add `/mnt/games/SteamLibrary` in Steam > Settings > Storage
- [ ] Test gamescope per-game: `gamescope -W 2560 -H 1440 -f -- %command%` in Steam launch options
- [ ] Test Steam Game Mode session in SDDM
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
| Gamescope (CLI + session) | `gamescope-session-git` | AUR (bootstrap) |
| hyprpolkitagent | AUR package | AUR (bootstrap) |
| HDD partition + mount | bootstrap.sh | parted + fstab |
| Hyprland WM + config | home-manager | `programs.hyprland` |
| waybar, swaync, rofi, etc. | home-manager | `programs.*` / `services.*` |
| kitty, firefox | home-manager | `programs.*` |
| gamemode, mangohud config | home-manager | `programs.*` |
| protonup-qt, goverlay, discord | home-manager | `home.packages` |
| nvtop, gwe, pavucontrol | home-manager | `home.packages` |
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
