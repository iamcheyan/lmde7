#!/bin/bash

# LMDE 7 Rime (XSB & Japanese) Configuration Script
# Automatically sets up Fcitx5-Rime and syncs from iamcheyan/rime

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for sudo permissions (needed for apt)
if [ "$EUID" -ne 0 ]; then
    log_warn "This script requires root privileges to install packages."
    exec sudo "$0" "$@"
fi

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   Rime (XSB & Japanese) Setup Helper        ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# --- Step 1: Install Dependencies ---

log_info "Step 1: Installing Fcitx5 and Rime Lua dependencies..."
# Based on your README requirements for Debian/LMDE
apt update
apt install -y fcitx5 fcitx5-rime librime-plugin-lua librime-tools git

# --- Step 2: Sync Configuration ---

RIME_DIR="$HOME/.local/share/fcitx5/rime"
REPO_URL="https://github.com/iamcheyan/rime.git"

# Note: We need to run the following as the actual user, not root
REAL_USER=$SUDO_USER
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
RIME_DIR_REAL="$REAL_HOME/.local/share/fcitx5/rime"

log_info "Step 2: Syncing configuration from GitHub to $RIME_DIR_REAL..."

# Create parent directory if not exists
sudo -u "$REAL_USER" mkdir -p "$(dirname "$RIME_DIR_REAL")"

if [ -d "$RIME_DIR_REAL" ]; then
    log_warn "Directory $RIME_DIR_REAL already exists."
    read -p "Do you want to back it up and re-clone? [y/N]: " backup_choice
    if [[ "$backup_choice" =~ ^[yY]$ ]]; then
        BACKUP_NAME="${RIME_DIR_REAL}_backup_$(date +%Y%m%d_%H%M%S)"
        sudo -u "$REAL_USER" mv "$RIME_DIR_REAL" "$BACKUP_NAME"
        log_info "Backup created at $BACKUP_NAME"
    else
        log_info "Skipping clone, will attempt to pull updates instead."
        cd "$RIME_DIR_REAL" && sudo -u "$REAL_USER" git pull
    fi
fi

if [ ! -d "$RIME_DIR_REAL" ]; then
    sudo -u "$REAL_USER" git clone "$REPO_URL" "$RIME_DIR_REAL"
    log_success "Clone complete."
fi

# --- Step 3: Deployment ---

log_info "Step 3: Triggering Rime deployment (Rebuild)..."

if [ -f "$RIME_DIR_REAL/rebuild" ]; then
    cd "$RIME_DIR_REAL"
    # Execute the rebuild script as the real user
    sudo -u "$REAL_USER" bash ./rebuild
    log_success "Deployment commands executed."
else
    log_error "rebuild script not found in the repository!"
fi

# --- Step 4: System Integration ---

log_info "Step 4: Setting Fcitx5 as the default input method framework..."
# For Debian/LMDE, im-config is the standard way
if command -v im-config > /dev/null; then
    sudo -u "$REAL_USER" im-config -n fcitx5
    log_success "Fcitx5 set as default via im-config."
else
    log_warn "im-config not found. Please manually ensure Fcitx5 is your active framework."
fi

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       Rime Configuration Complete!          ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Next Steps:"
echo "1. Log out and log back in (or restart your session)."
echo "2. Ensure Fcitx5 is running: 'fcitx5 &'"
echo "3. In Fcitx5 Configuration, add 'Rime' to your input methods."
echo "4. Test with 'orq' (Lua date) to verify the installation."
echo ""
log_info "Enjoy typing with XSB and Japanese Romaji!"

exit 0
