#!/bin/bash

# LMDE 7 Software Initialization Script
# Based on user's manual: Apt for core tools, Flatpak for apps, and bloatware removal.

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

# Check for sudo/root
if [ "$EUID" -ne 0 ]; then
    log_warn "This script requires root privileges for apt operations."
    exec sudo "$0" "$@"
fi

# Get the real user for flatpak --user operations
REAL_USER=${SUDO_USER:-$(whoami)}

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}    LMDE 7 Software Initialization Helper    ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# --- Step 1: Remove System Bloatware ---
log_info "Step 1: Removing pre-installed software (Bloatware)..."

# List of packages to remove
REMOVE_PKGS=(
    "redshift-gtk"
    "thunderbird"
    "rhythmbox"
)

for pkg in "${REMOVE_PKGS[@]}"; do
    log_info "Removing $pkg..."
    apt-get remove --purge -y "$pkg"
done

log_info "Removing LibreOffice (Apt version)..."
apt-get remove --purge -y 'libreoffice*'
apt-get autoremove --purge -y

log_success "Bloatware removed."

# --- Step 2: Install Base Tools via Apt ---
log_info "Step 2: Installing core tools and fonts via Apt..."

apt-get update

# Core Tools
CORE_TOOLS=(
    "freerdp2-x11"
    "fcitx5"
    "fcitx5-rime"
    "vim"
    "sshpass"
    "sshfs"
    "unison"
    "linuxlogo"
    "xclip"
    "grub2-theme-mint-2k" # 4K Grub theme
)

# Fonts
FONTS=(
    "fonts-noto-cjk"
    "fonts-wqy-zenhei"
    "fonts-wqy-microhei"
    "fonts-liberation"
)

log_info "Installing packages: ${CORE_TOOLS[*]} ${FONTS[*]}"
apt-get install -y "${CORE_TOOLS[@]}" "${FONTS[@]}"

log_info "Refreshing font cache..."
fc-cache -fv

log_success "Core tools and fonts installed."

# --- Step 3: Flatpak Setup ---
log_info "Step 3: Checking Flatpak and Flathub..."

if ! command -v flatpak >/dev/null 2>&1; then
    log_info "Installing flatpak..."
    apt-get install -y flatpak
fi

# Add Flathub if not exists
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

FLATPAK_APPS=(
    "com.google.Chrome"
    "com.visualstudio.code"
    "com.microsoft.Edge"
    "org.keepassxc.KeePassXC"
    "com.qq.QQ"
    "com.tencent.WeChat"
    "org.libreoffice.LibreOffice"
    "com.spotify.Client"
    "org.mozilla.Thunderbird"
    "org.videolan.VLC"
    "com.wps.Office"
    "com.dropbox.Client"
    "org.freefilesync.FreeFileSync"
    "com.github.hluk.copyq"
    "org.filezillaproject.Filezilla"
    "io.github.cboxdoerfer.FSearch"
    "org.telegram.desktop"
    "org.freedesktop.Platform.Compat.i386"
    "org.freedesktop.Platform.GL.default"
    "org.gnome.FontManager"
    "org.gnome.font-viewer"
    "org.winehq.Wine"
)

log_info "Installing Flatpak applications (this may take a long time)..."
for app in "${FLATPAK_APPS[@]}"; do
    log_info "Installing $app..."
    # Using -y for non-interactive
    flatpak install -y flathub "$app"
done

# --- Step 4: Wine Configuration ---
log_info "Step 4: Configuring Wine (Flatpak)..."

# Run overrides as the real user
sudo -u "$REAL_USER" flatpak override --user --filesystem=/home org.winehq.Wine
# Example env var if needed (provided in user prompt)
# sudo -u "$REAL_USER" flatpak override --user --env=VARIABLE_NAME=value org.winehq.Wine

log_success "Wine overrides applied for user $REAL_USER."

# --- Final Step: Summary ---
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}    Initialization Process Completed!        ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
log_info "Next Steps:"
echo "1. Configure Fcitx5 via 'Fcitx 5 Configuration'."
echo "2. Enjoy your clean, Flatpak-based system!"
echo ""

exit 0
