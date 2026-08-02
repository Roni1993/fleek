#!/usr/bin/env bash
# ── CachyOS Gaming PC Bootstrap ─────────────────────────────────
# Run once after a fresh CachyOS KDE install (with user "roni").
# Handles system packages, storage, Nix, and applies the HM config.
# Safe to re-run — all commands are idempotent.
#
# Manual steps before this script:
#   1. Update BIOS
#   2. Download CachyOS ISO (KDE variant)
#   3. Flash to USB, boot from it
#   4. In Calamares: NVMe → /boot/efi (1GB) + / (Btrfs, rest)
#                    User: roni
#                    HDD: leave untouched (script handles it)
#   5. Reboot, log into KDE session, open Konsole, run this script.
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

section() { echo -e "\n${GREEN}>>>${NC} $*"; }
warn()   { echo -e "${YELLOW}!!!${NC} $*"; }
die()    { echo -e "${RED}ERR:${NC} $*" >&2; exit 1; }

# ── Preflight ────────────────────────────────────────────────────

[ "$USER" = "roni" ] || warn "Expected user 'roni', got '$USER'."
command -v pacman &>/dev/null || die "pacman not found — are you on CachyOS?"

# ── 0. Sudo safety check ─────────────────────────────────────────
# Before running any sudo commands, verify the password works.
# If it doesn't, offer a root fallback to set up passwordless sudo.

section "Sudo password check"
if ! sudo -v 2>/dev/null; then
  warn "sudo failed — password may be wrong or sudoers is misconfigured."
  echo ""
  echo "  Two options:"
  echo "    1. Reset password: boot from CachyOS USB, mount NVMe,"
  echo "       arch-chroot /mnt && passwd roni"
  echo "    2. Use root password to enable passwordless sudo NOW:"
  echo "       su -c 'echo \"%wheel ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/wheel-nopasswd'"
  echo ""
  printf "Enter '2' to attempt root fallback, or anything else to abort: "
  read -r choice
  if [ "$choice" = "2" ]; then
    echo "Running: su -c 'echo ... > /etc/sudoers.d/wheel-nopasswd'"
    su -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel-nopasswd' || die "Root fallback failed."
    echo "Passwordless sudo enabled. Continuing..."
    sudo -v || die "sudo still broken after root fallback — check /etc/sudoers."
  else
    die "Cannot proceed without sudo. Run option 1 (USB chroot) first, then re-run this script."
  fi
else
  echo "sudo works."
fi

# ── 1. System update ────────────────────────────────────────────

section "System update"
sudo pacman -Syu --noconfirm

# ── 2. Base tools + AUR helper ──────────────────────────────────

section "Base development tools"
sudo pacman -S --noconfirm --needed base-devel git curl wget

if ! command -v paru &>/dev/null; then
  section "Installing paru (AUR helper)"
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  (cd /tmp/paru && makepkg -si --noconfirm)
  rm -rf /tmp/paru
fi

# ── 3. Gaming system packages ───────────────────────────────────

section "NVIDIA driver stack (userspace) — must precede gaming-meta"
# cachyos-gaming-meta depends on the virtual 'lib32-vulkan-driver' provider.
# Installing the NVIDIA stack first satisfies it; otherwise --noconfirm would
# auto-select the first provider (lib32-nvidia-390xx-utils) and conflict.
# The kernel module is installed by the CachyOS installer (chwd) during setup.
sudo pacman -S --noconfirm --needed nvidia-utils lib32-nvidia-utils

section "CachyOS gaming meta-package (kernel, drivers, Steam, Wine)"
sudo pacman -S --noconfirm --needed cachyos-gaming-meta

section "CachyOS gamescope-session (Steam Deck Game Mode UI)"
sudo pacman -S --noconfirm --needed gamescope-session-cachyos

section "hyprpolkitagent (privilege escalation for Hyprland)"
sudo pacman -S --noconfirm --needed hyprpolkitagent

# ── 3b. Remove noctalia (notification daemon) ────────────────────
# noctalia ships with CachyOS KDE and claims org.freedesktop.Notifications
# on D-Bus, which prevents swaync (configured in our gaming profile)
# from starting. Remove it so swaync can claim the name.

if pacman -Q noctalia &>/dev/null; then
  section "Removing noctalia (notification daemon) — conflicts with swaync"
  sudo pacman -R --noconfirm noctalia
else
  echo "noctalia not installed, skipping."
fi

# ── 4. NVIDIA verification ──────────────────────────────────────

section "Verifying NVIDIA drivers"
if command -v nvidia-smi &>/dev/null; then
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader \
    || warn "nvidia-smi reported an error (driver may not be loaded yet). Continue anyway."
else
  warn "nvidia-smi not found. GPU drivers may not be loaded."
  warn "Run: sudo pacman -S nvidia-dkms && reboot"
fi

# ── 5. HDD setup (NTFS staging, read-only) ──────────────────────
# Per wayfinder #6: the 4TB HDD stays NTFS untouched through the
# transition. It is mounted READ-ONLY at /mnt/staging so the Phase-3
# restore (keys, Firefox profile) can read it. NO wiping, NO repartition.
# After private data migrates to the Pi (#12), reformat to a single ext4
# /mnt/games — that is owned by ticket #12, not this script.

HDD_DEV=""
# Scan all SATA and NVMe devices for a disk >= 3.5 TB (accounts for
# manufacturer vs OS size reporting). Exclude the boot NVMe (<= 2TB)
# and removable devices (USB stick).
for dev in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
  [ -b "$dev" ] || continue
  # Skip the boot NVMe (CachyOS is installed on nvme0n1, ~1.8TB)
  [[ "$dev" == /dev/nvme0n1 ]] && continue
  size=$(lsblk -dbno SIZE "$dev" 2>/dev/null | head -1 || true)
  if [ "$size" -ge 3500000000000 ] 2>/dev/null; then
    HDD_DEV="$dev"
    break
  fi
done

if [ -z "$HDD_DEV" ]; then
  warn "Could not auto-detect the 4 TB HDD."
  warn "Available block devices:"
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
  printf "Enter HDD device (e.g. /dev/sda) or leave empty to skip: "
  read -r HDD_DEV
fi

if [ -n "$HDD_DEV" ] && ! mount | grep -q "/mnt/staging"; then
  HDD_PART="${HDD_DEV}1"
  if [ ! -b "$HDD_PART" ]; then
    warn "No partition found on $HDD_DEV — expected NTFS part1. Skipping staging mount."
    warn "You may need to mount it manually for the Phase-3 restore."
  else
    section "Mounting $HDD_PART read-only at /mnt/staging"
    HDD_UUID=$(sudo blkid -s UUID -o value "$HDD_PART")
    sudo mkdir -p /mnt/staging
    if ! grep -q "$HDD_UUID" /etc/fstab; then
      echo "UUID=$HDD_UUID  /mnt/staging  ntfs  ro,noatime,nofail  0 0" | sudo tee -a /etc/fstab
    fi
    sudo mount /mnt/staging 2>/dev/null || sudo mount -o ro /mnt/staging || \
      warn "Mount failed. Check the partition and fstab entry; restore data manually."
    lsblk "$HDD_DEV"
    echo "/mnt/staging ready (read-only). Phase-3 will restore keys + Firefox from /mnt/staging/backup-for-cachyos."
  fi
elif mount | grep -q "/mnt/staging"; then
  section "HDD already mounted read-only at /mnt/staging"
fi

# ── 6. Nix installation ──────────────────────────────────────────

section "Installing Determinate Nix"
if ! command -v nix &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  # Source nix into this shell
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  echo "Nix already installed: $(nix --version)"
fi

# ── 7. Nix flakes ────────────────────────────────────────────────

section "Enabling Nix flakes"
mkdir -p ~/.config/nix
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  echo "Flakes enabled."
else
  echo "Flakes already configured."
fi

# ── 7b. Clear conflicting files before HM activation ────────────
# Home-manager manages these paths as symlinks into the nix store.
# Pre-existing files/dirs block the symlink creation and cause HM to
# abort. Back up any that exist, then remove them.
#
# List derived from: shell.nix (bash), gaming.nix (kitty, waybar,
# swaync, rofi, hyprland), programs.nix (starship, nushell, etc.),
# and home.nix (fontconfig).

CONFLICT_PATHS=(
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.profile"
  "$HOME/.config/kitty/kitty.conf"
  "$HOME/.config/starship.toml"
  "$HOME/.config/nushell/env.nu"
  "$HOME/.config/nushell/config.nu"
  "$HOME/.config/waybar/config.jsonc"
  "$HOME/.config/waybar/style.css"
  "$HOME/.config/swaync/config.json"
  "$HOME/.config/swaync/style.css"
  "$HOME/.config/rofi/config.rasi"
  "$HOME/.config/hypr/hyprland.conf"
  "$HOME/.config/hypr/hyprlock.conf"
  "$HOME/.config/hypr/hypridle.conf"
  "$HOME/.config/direnv/direnv.toml"
  "$HOME/.config/broot/config.toml"
  "$HOME/.config/atuin/config.toml"
  "$HOME/.config/git/config"
  "$HOME/.config/gh/config.yml"
  "$HOME/.mozilla/firefox/profiles.ini"
)

section "Checking for files that conflict with home-manager"
BACKUP_DIR="$HOME/.hm-backup-$(date +%Y%m%d-%H%M%S)"
found_any=false
for path in "${CONFLICT_PATHS[@]}"; do
  if [ -f "$path" ] && [ ! -L "$path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${path#$HOME/}")"
    cp "$path" "$BACKUP_DIR/${path#$HOME/}"
    rm -f "$path"
    warn "Backed up and removed: $path"
    found_any=true
  fi
done
if [ "$found_any" = false ]; then
  echo "No conflicting files found."
else
  echo "Backups saved to: $BACKUP_DIR"
  echo "You can restore them later if needed."
fi

# ── 8. Home-manager apply ────────────────────────────────────────

REPO_URL="${FLEEK_REPO_URL:-https://github.com/Roni1993/fleek.git}"
REPO_DIR="$HOME/projects/fleek"

section "Setting up fleek home-manager config"
if [ -d "$REPO_DIR/.git" ]; then
  echo "Repo exists. Pulling latest..."
  git -C "$REPO_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR" || {
    warn "Git clone failed — is the repo pushed and SSH key added?"
    warn "If you haven't pushed yet, push from your WSL machine first."
    warn "Repo URL: $REPO_URL"
    warn "You can re-run this script after pushing."
    exit 1
  }
fi

section "Applying gaming profile"
nix run "$REPO_DIR#apply-gaming"

# ── 8b. Project checkouts ──────────────────────────────────────
# Clone every local project into ~/projects, mirroring the old WSL layout.
# Format: "url|dir|branch". Skip if the dir already exists (idempotent).
# Private repos (homelab, gameServerHosting) need `gh auth login` or an SSH
# key added to GitHub; clone failure for them is a warning, not an abort.

PROJECTS=(
  "https://github.com/Roni1993/homelab.git|homelab|main"
  "https://github.com/Trusty-Serva/gameServerHosting.git|gameServerHosting|main"
  "https://github.com/thebracket/JetBrainsBevy|JetBrainsBevy|main"
  "https://github.com/raspberrypi/pico-examples.git|pico-examples|master"
  "https://github.com/steam-deck-controller/steam-deck-controller.git|steam-deck-controller|freertos"
)

section "Cloning projects into ~/projects"
for entry in "${PROJECTS[@]}"; do
  url="${entry%%|*}"; rest="${entry#*|}"; dir="${rest%%|*}"; branch="${rest#*|}"
  target="$HOME/projects/$dir"
  if [ -d "$target/.git" ]; then
    echo "  $dir: already present, pulling..."
    git -C "$target" pull --ff-only 2>/dev/null || echo "  $dir: pull skipped (uncommitted changes?)"
  else
    mkdir -p "$HOME/projects"
    echo "  $dir: cloning ($branch)..."
    if git clone --branch "$branch" --single-branch "$url" "$target" 2>/dev/null; then
      echo "  $dir: OK"
    else
      warn "$dir: clone failed. If private, run \`gh auth login\` first (or add SSH key), then re-run."
    fi
  fi
done

# ── 9. Post-bootstrap verification ──────────────────────────────

section "Post-bootstrap verification"

errors=0

echo -n "  NVIDIA driver... "
if nvidia-smi --query-gpu=name --format=csv,noheader &>/dev/null; then
  echo "OK ($(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null))"
else
  echo "FAIL"; errors=$((errors + 1))
fi

echo -n "  HDD at /mnt/staging... "
if mountpoint -q /mnt/staging 2>/dev/null; then
  echo "OK ($(lsblk -no SIZE /dev/sda2 2>/dev/null | head -1))"
else
  echo "NOT MOUNTED"; errors=$((errors + 1))
fi

echo -n "  Home-manager generation... "
if home-manager generations 2>/dev/null | head -1 | grep -q current; then
  echo "OK"
else
  echo "FAIL"; errors=$((errors + 1))
fi

echo -n "  Nix daemon... "
if systemctl status nix-daemon &>/dev/null; then
  echo "OK"
else
  echo "NOT RUNNING"; errors=$((errors + 1))
fi

echo -n "  Hyprland config... "
if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
  echo "OK"
else
  echo "MISSING"; errors=$((errors + 1))
fi

echo -n "  Kitty... "
if command -v kitty &>/dev/null; then
  echo "OK ($(kitty --version))"
else
  echo "NOT FOUND"; errors=$((errors + 1))
fi

echo -n "  SDDM autologin... "
if grep -q "Session=hyprland" /etc/sddm.conf 2>/dev/null; then
  echo "OK"
else
  echo "$(grep 'Session=' /etc/sddm.conf 2>/dev/null || echo 'NOT SET')"
fi

echo ""
if [ "$errors" -gt 0 ]; then
  warn "$errors check(s) failed — review above and fix manually."
else
  echo "All checks passed."
fi

# ── 10. Done ────────────────────────────────────────────────────

echo ""
echo "==========================================="
echo "  Bootstrap complete!"
echo ""
echo "  Next steps:"
echo "    1. Reboot"
echo "    2. At SDDM, select 'Hyprland' session"
echo "    3. Login — waybar, swaync, rofi should start"
echo "    4. Restore keys + Firefox from /mnt/staging/backup-for-cachyos"
echo "       (see ROADMAP.md Phase 3)"
echo "    5. Run protonup-qt to install GE-Proton"
echo "    6. HDD becomes a games disk later — owned by wayfinder ticket #12"
echo "==========================================="
