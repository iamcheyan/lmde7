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
log_info "Step 2: Installing dependencies (git, make, inotify-tools)..."
apt-get update
apt-get install -y git make inotify-tools gettext
if [ $? -ne 0 ]; then
    log_error "Failed to install dependencies."
    exit 1
fi

# --- Step 3: Clone and Install ---
log_info "Step 3: Cloning grub-btrfs from GitHub..."
TEMP_DIR=$(mktemp -d)
git clone https://github.com/Antynea/grub-btrfs.git "$TEMP_DIR"

log_info "Installing grub-btrfs..."
cd "$TEMP_DIR"
make install
if [ $? -eq 0 ]; then
    log_success "grub-btrfs installed successfully."
else
    log_error "Installation failed."
    exit 1
fi

# --- Step 4: Initial GRUB Update ---
log_info "Step 4: Updating GRUB configuration..."
update-grub
log_success "GRUB menu updated."

# --- Step 5: Enable Monitoring Daemon ---
log_info "Step 5: Enabling grub-btrfsd service (auto-update on snapshot)..."

# Configuration: Make sure it monitors Timeshift's location
# Most Debian/LMDE systems use /run/timeshift/backup or /run/timeshift/btrfs
# grub-btrfs usually detects this, but we'll ensure the service is happy.

systemctl enable --now grub-btrfsd
if systemctl is-active --quiet grub-btrfsd; then
    log_success "Monitoring daemon is running."
else
    log_warn "Daemon failed to start. You may need to run 'update-grub' manually after snapshots."
fi

# --- Step 6: Summary ---
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       grub-btrfs Setup Complete!            ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
log_info "How to use:"
echo "1. When Timeshift creates a snapshot (manual or scheduled),"
echo "   the GRUB menu will be automatically updated."
echo "2. On next boot, you will see a 'Linx Snapshots' submenu in GRUB."
echo "3. Select a snapshot to boot into it in Read-Only mode."
echo ""
echo -e "${YELLOW}Tip: To make a snapshot bootable/writable after booting into it,${NC}"
echo -e "${YELLOW}     use Timeshift to 'Restore' that snapshot.${NC}"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

exit 0
