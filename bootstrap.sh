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

[ "$USER" = "roni" ] || warn "Expected user 'roni', got '$USER'. Continue? [y/N] " && read -r c && [ "$c" = "y" ] || true
command -v pacman &>/dev/null || die "pacman not found — are you on CachyOS?"

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
for dev in /dev/sda /dev/sdb /dev/nvme1n1; do
  size=$(lsblk -bno SIZE "$dev" 2>/dev/null || true)
  if [ "$size" -ge 3900000000000 ] 2>/dev/null; then  # >= ~3.9 TB = 4 TB disk
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
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
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

# ── 9. Done ─────────────────────────────────────────────────────

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
