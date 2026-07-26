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

section "CachyOS gaming meta-package (kernel, drivers, Steam, Wine)"
sudo pacman -S --noconfirm --needed cachyos-gaming-meta

section "AUR: gamescope-session (Steam Deck Game Mode UI)"
paru -S --noconfirm --needed gamescope-session-git

section "AUR: hyprpolkitagent (privilege escalation for Hyprland)"
paru -S --noconfirm --needed hyprpolkitagent

# ── 4. NVIDIA verification ──────────────────────────────────────

section "Verifying NVIDIA drivers"
if command -v nvidia-smi &>/dev/null; then
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
else
  warn "nvidia-smi not found. GPU drivers may not be loaded."
  warn "Run: sudo pacman -S nvidia-dkms && reboot"
fi

# ── 5. HDD setup (4 TB game library) ────────────────────────────

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

if [ -n "$HDD_DEV" ] && ! mount | grep -q "/mnt/games"; then
  HDD_PART="${HDD_DEV}1"
  if [ ! -b "$HDD_PART" ]; then
    section "Partitioning $HDD_DEV as a single ext4 partition"
    warn "This will ERASE all data on $HDD_DEV!"
    lsblk "$HDD_DEV"
    printf "Proceed? [y/N] "
    read -r c
    if [ "$c" = "y" ]; then
      sudo parted "$HDD_DEV" -- mklabel gpt
      sudo parted "$HDD_DEV" -- mkpart primary ext4 0% 100%
      sleep 2
      sudo mkfs.ext4 -F "$HDD_PART"
    else
      warn "Skipping HDD setup."
      HDD_PART=""
    fi
  fi

  if [ -n "$HDD_PART" ]; then
    section "Mounting $HDD_PART at /mnt/games"
    HDD_UUID=$(sudo blkid -s UUID -o value "$HDD_PART")
    sudo mkdir -p /mnt/games
    if ! grep -q "$HDD_UUID" /etc/fstab; then
      echo "UUID=$HDD_UUID  /mnt/games  ext4  defaults,noatime  0 2" | sudo tee -a /etc/fstab
    fi
    sudo mount /mnt/games
    sudo chown roni:roni /mnt/games

    # Create Steam library directory structure
    mkdir -p /mnt/games/SteamLibrary
    echo "/mnt/games ready. Add it in Steam > Settings > Storage."
  fi
elif mount | grep -q "/mnt/games"; then
  section "HDD already mounted at /mnt/games"
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
echo "    4. Open Steam > Settings > Storage"
echo "       Add /mnt/games/SteamLibrary"
echo "    5. Run protonup-qt to install GE-Proton"
echo "==========================================="
