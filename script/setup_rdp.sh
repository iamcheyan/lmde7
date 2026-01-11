#!/bin/bash

# LMDE 7 / Debian RDP (Remote Desktop) Configuration Script
# One-click XRDP setup and verification helper

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
    log_warn "This script requires root privileges to configure system services."
    exec sudo "$0" "$@"
fi

# Get the real user (since we are running as root/sudo)
REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(eval echo ~$REAL_USER)

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}      RDP One-Click Configuration Helper     ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# --- Step 1: Install XRDP ---
log_info "Step 1: Checking XRDP installation..."

if dpkg -l | grep -q xrdp; then
    log_success "xrdp is already installed."
else
    log_info "xrdp not found. Installing xrdp and xorgxrdp..."
    apt-get update
    apt-get install -y xrdp xorgxrdp
    if [ $? -eq 0 ]; then
        log_success "XRDP installed successfully."
    else
        log_error "Failed to install XRDP. Please check your internet connection."
        exit 1
    fi
fi

# --- Step 2: Permission & Group ---
log_info "Step 2: Configuring user permissions..."
# Add xrdp user to ssl-cert group to avoid cert errors
if getent group ssl-cert > /dev/null; then
    usermod -a -G ssl-cert xrdp
    log_success "Added 'xrdp' user to 'ssl-cert' group."
fi

# --- Step 3: Session Configuration ---
log_info "Step 3: Configuring desktop session for $REAL_USER..."

# LMDE default is usually Cinnamon. Let's create .xsession if it doesn't exist
XSESSION_FILE="$REAL_HOME/.xsession"
XSESSIONRC_FILE="$REAL_HOME/.xsessionrc"

# We check for Cinnamon session
if [ -f "/usr/bin/cinnamon-session" ]; then
    DESKTOP_EXEC="cinnamon-session"
    log_info "Detected Cinnamon desktop."
elif [ -f "/usr/bin/mate-session" ]; then
    DESKTOP_EXEC="mate-session"
    log_info "Detected MATE desktop."
elif [ -f "/usr/bin/xfce4-session" ]; then
    DESKTOP_EXEC="startxfce4"
    log_info "Detected XFCE desktop."
else
    DESKTOP_EXEC="x-session-manager"
    log_warn "Could not pinpoint desktop environment, using default x-session-manager."
fi

# Create .xsession for the user
echo "$DESKTOP_EXEC" > "$XSESSION_FILE"
chown "$REAL_USER:$REAL_USER" "$XSESSION_FILE"
log_success "Configured .xsession for $REAL_USER."

# Fix for Polkit authentication in RDP sessions (avoid popups)
POLKIT_CONF="/etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla"
if [ ! -f "$POLKIT_CONF" ]; then
    log_info "Adding Polkit rule to prevent 'Authentication Required' popups in RDP..."
    mkdir -p "$(dirname "$POLKIT_CONF")"
    cat > "$POLKIT_CONF" <<EOF
[Allow Colord for all users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
fi

# --- Step 4: Service Management ---
log_info "Step 4: Starting XRDP service..."
systemctl enable xrdp
systemctl restart xrdp
log_success "XRDP service is active and enabled."

# --- Step 5: Firewall ---
log_info "Step 5: Checking Firewall (UFW)..."
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        log_info "Allowing RDP port (3389) in UFW..."
        ufw allow 3389/tcp
        log_success "Port 3389 allowed."
    fi
fi

# --- Step 6: Summary ---
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       RDP Configuration Complete!           ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

IP_ADDRS=$(hostname -I | awk '{print $1}')
log_info "Connection Info:"
echo "---------------------------------------------"
echo -e "   IP Address:  ${YELLOW}$IP_ADDRS${NC}"
echo -e "   RDP Port:    ${YELLOW}3389${NC}"
echo -e "   Username:    ${YELLOW}$REAL_USER${NC}"
echo "---------------------------------------------"
echo ""
log_warn "IMPORTANT NOTES:"
echo "1. If you are currently logged in LOCALLY on this machine,"
echo "   some desktop environments (like Cinnamon) may not allow"
echo "   a second concurrent session. You might need to log out"
echo "   locally before connecting via RDP."
echo "2. Use Microsoft Remote Desktop (Windows) or any RDP client."
echo ""

exit 0
