#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu instance with:
#   - Nix (Determinate Systems installer, flakes enabled out of the box)
#   - Docker CE (system service, user added to docker group)
#   - This repo cloned to ~/fleek
#   - Home Manager applied for the chosen profile

set -euo pipefail

REPO_URL="https://github.com/Roni1993/fleek.git"
REPO_DIR="$HOME/fleek"

# ── helpers ────────────────────────────────────────────────────────────────────
info()  { printf '\033[1;34m=> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m✓  %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m!  %s\033[0m\n' "$*"; }
die()   { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" &>/dev/null || die "'$1' is required but not found. Install it and retry."
}

# ── 1. System prerequisites ────────────────────────────────────────────────────
info "Updating apt and installing prerequisites"
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl git ca-certificates gnupg lsb-release xz-utils

# ── 2. Docker CE ───────────────────────────────────────────────────────────────
if command -v docker &>/dev/null; then
  ok "Docker already installed ($(docker --version))"
else
  info "Installing Docker CE"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ok "Docker CE installed"
fi

# Add current user to docker group so no sudo needed
if ! groups | grep -qw docker; then
  info "Adding $USER to docker group"
  sudo usermod -aG docker "$USER"
  warn "Group change takes effect in new shell sessions (or run: newgrp docker)"
fi

# On WSL, dockerd doesn't run as a system service automatically — start it if needed
if grep -qi microsoft /proc/version 2>/dev/null; then
  if ! sudo service docker status &>/dev/null; then
    info "WSL detected — starting Docker daemon"
    sudo service docker start
  fi
fi

# ── 3. Nix (Determinate Systems — enables flakes by default) ──────────────────
if command -v nix &>/dev/null; then
  ok "Nix already installed ($(nix --version))"
else
  info "Installing Nix via Determinate Systems installer"
  curl --proto '=https' --tlsv1.2 -sSf \
    https://install.determinate.systems/nix | sh -s -- install --no-confirm
  # Source nix into the current shell so subsequent commands can use it
  # shellcheck source=/dev/null
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  ok "Nix installed"
fi

# Confirm flakes are available
nix flake --help &>/dev/null || die "Nix flakes not available — check your Nix installation"

# ── 4. Clone the fleek repo ────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  ok "Repo already cloned at $REPO_DIR"
else
  info "Cloning $REPO_URL → $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
  ok "Repo cloned"
fi

# ── 5. Choose environment and apply Home Manager ──────────────────────────────
environment="${1:-}"

if [ -z "$environment" ]; then
  printf "Environment [work/private]: " >&2
  read -r environment
fi

case "$environment" in
  work|w|WORK|Work)       target="${USER}@work" ;;
  private|p|PRIVATE|Private) target="${USER}@private" ;;
  *) die "Unknown environment '$environment'. Choose 'work' or 'private'." ;;
esac

info "Applying Home Manager profile: $target"
nix run "$REPO_DIR#apply-${environment%@*}" -- --impure 2>&1 \
  || nix run "$REPO_DIR#apply-current" -- "$environment" --impure

ok "Home Manager profile '$target' applied!"

# ── 6. Post-install notes ──────────────────────────────────────────────────────
cat <<'EOF'

────────────────────────────────────────────────────────
  Setup complete. A few manual steps remain:

  1. Start a new shell (or run: source ~/.nix-profile/etc/profile.d/nix.sh)

  2. Work profile — GPG key + pass store:
       gpg --batch --gen-key <params>   # or import an existing key
       pass init <GPG-KEY-ID>

  3. Docker group (if you saw the group-change warning above):
       newgrp docker   # or log out and back in

  4. aws-sso login    # to authenticate with AWS Identity Center
────────────────────────────────────────────────────────
EOF
