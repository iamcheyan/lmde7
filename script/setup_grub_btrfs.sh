#!/bin/bash

# LMDE 7 / Debian grub-btrfs Installation Script
# Adds Timeshift snapshots to the GRUB boot menu

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
    log_warn "This script requires root privileges."
    exec sudo "$0" "$@"
fi

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}      grub-btrfs One-Click Installer         ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# --- Step 1: Prerequisite Check (Btrfs) ---
log_info "Step 1: Checking filesystem..."
if ! findmnt / -n -o FSTYPE | grep -q "btrfs"; then
    log_error "Root filesystem is NOT Btrfs. grub-btrfs requires a Btrfs partition."
    exit 1
fi
log_success "Found Btrfs root filesystem."

# --- Step 2: Install Dependencies ---
log_info "Step 2: Installing dependencies (timeshift, build-essential, git, make, etc.)..."
apt-get update
apt-get install -y timeshift build-essential git make inotify-tools gettext
if [ $? -ne 0 ]; then
    log_error "Failed to install dependencies."
    exit 1
fi

# --- Step 3: Clone and Install grub-btrfs ---
log_info "Step 3: Installing grub-btrfs..."
TEMP_DIR=$(mktemp -d)
git clone https://github.com/Antynea/grub-btrfs.git "$TEMP_DIR/grub-btrfs"
cd "$TEMP_DIR/grub-btrfs"
make install
if [ $? -ne 0 ]; then
    log_error "grub-btrfs installation failed."
    exit 1
fi
log_success "grub-btrfs installed."

# --- Step 4: Install timeshift-autosnap-apt ---
log_info "Step 4: Installing timeshift-autosnap-apt..."
log_info "This will automatically create a snapshot before any 'apt install/upgrade' command."
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git "$TEMP_DIR/timeshift-autosnap-apt"
cd "$TEMP_DIR/timeshift-autosnap-apt"
make install
if [ $? -ne 0 ]; then
    log_error "timeshift-autosnap-apt installation failed."
    exit 1
fi
log_success "timeshift-autosnap-apt installed."

# --- Step 5: Initial GRUB Update ---
log_info "Step 5: Updating GRUB configuration..."
update-grub
log_success "GRUB menu updated."

# --- Step 6: Enable Monitoring Daemon ---
log_info "Step 6: Enabling grub-btrfsd service..."
systemctl enable --now grub-btrfsd
if systemctl is-active --quiet grub-btrfsd; then
    log_success "Monitoring daemon (grub-btrfsd) is running."
else
    log_warn "Daemon failed to start. You may need to run 'update-grub' manually after snapshots."
fi

# --- Step 7: Summary ---
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       Btrfs Snapshot Stack Completed!       ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
log_info "Features now active:"
echo "1. [Auto-Snap] Anytime you run 'apt install', a snapshot is created automatically."
echo "2. [Auto-Menu] grub-btrfsd will detect new snapshots and add them to GRUB."
echo "3. [Boot-Menu] Restart to see 'Linux Snapshots' in your boot menu."
echo ""
log_warn "Reminder: Ensure you have configured Timeshift (GUI) at least once"
log_warn "to set up your Btrfs backup location!"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

exit 0
