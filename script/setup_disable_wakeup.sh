#!/bin/bash

# LMDE 7 Disable Automatic Wake-up Script
# Prevents the system from automatically restarting after hibernation/sleep.

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
    log_warn "This script requires root privileges to modify system configuration."
    exec sudo "$0" "$@"
fi

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   Disable Automatic Wake-up Helper          ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "This script prevents your Linux system from waking up immediately after hibernation."
echo "It creates a systemd sleep script to disable ACPI wake-up devices before sleep."
echo ""

# --- Step 1: Check Current Status ---

log_info "Current ACPI Wake-up Status (/proc/acpi/wakeup):"
cat /proc/acpi/wakeup
echo ""

# --- Step 2: Create the systemd-sleep script ---

SLEEP_SCRIPT="/usr/lib/systemd/system-sleep/disable_automatic_wake-up"

log_info "Creating sleep script at $SLEEP_SCRIPT..."

cat <<'EOF' | sudo tee "$SLEEP_SCRIPT" > /dev/null
#!/bin/sh

# This script disables all enabled ACPI wake-up devices before hibernation/suspend.
# This prevents unintended immediate restarts after the system enters sleep.

case $1 in
    pre)
        # Find all 'enabled' devices and toggle them to 'disabled'
        # Writing the device name to /proc/acpi/wakeup toggles its status.
        grep 'enabled' /proc/acpi/wakeup | cut -f1 -d' ' | while read -r device; do
            echo "$device" > /proc/acpi/wakeup
        done
        ;;
    post)
        # Optional: You could re-enable them here if you want them to work while the system is RUNNING,
        # but usually, these are for waking from sleep specifically.
        ;;
esac
EOF

log_info "Setting executable permissions on $SLEEP_SCRIPT..."
sudo chmod +x "$SLEEP_SCRIPT"

log_success "Sleep script created and configured."

# --- Step 3: Optional immediate apply ---

echo ""
read -p "Do you want to apply this change immediately to the current session? [y/N]: " apply_now
if [[ "$apply_now" =~ ^[yY]$ ]]; then
    log_info "Disabling CURRENTLY enabled wake-up devices..."
    grep 'enabled' /proc/acpi/wakeup | cut -f1 -d' ' | while read -r device; do
        echo "$device" > /proc/acpi/wakeup
    done
    log_success "Applied. New status:"
    cat /proc/acpi/wakeup
else
    log_info "Skipping immediate apply. It will be applied automatically before the next sleep."
fi

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       Configuration Complete!               ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
log_info "Your system should now stay hibernated/suspended without auto-restarting."
exit 0
