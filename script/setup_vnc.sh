#!/bin/bash

# LMDE 7 / Debian VNC (TigerVNC) Configuration Script
# One-click VNC server setup (Virtual Desktop)

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

# Get the real user
REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(eval echo ~$REAL_USER)

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}      VNC One-Click Configuration Helper     ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# --- Step 1: Install TigerVNC ---
log_info "Step 1: Installing TigerVNC Server..."

apt-get update
apt-get install -y tigervnc-standalone-server tigervnc-common tigervnc-tools

if [ $? -eq 0 ]; then
    log_success "TigerVNC installed successfully."
else
    log_error "Failed to install TigerVNC."
    exit 1
fi

# --- Step 2: Set VNC Password ---
log_info "Step 2: Setting VNC password for $REAL_USER..."
VNC_DIR="$REAL_HOME/.vnc"

if [ ! -d "$VNC_DIR" ]; then
    sudo -u "$REAL_USER" mkdir -p "$VNC_DIR"
fi

# Check if password already exists
if [ -f "$VNC_DIR/passwd" ]; then
    log_warn "VNC password already exists."
    read -p "Do you want to reset it? [y/N]: " choice
    if [[ "$choice" =~ ^[yY]$ ]]; then
        sudo -u "$REAL_USER" vncpasswd
    fi
else
    sudo -u "$REAL_USER" vncpasswd
fi

# --- Step 3: Configure Xstartup ---
log_info "Step 3: Configuring xstartup session..."

XSTARTUP="$VNC_DIR/xstartup"

# Backup existing one
if [ -f "$XSTARTUP" ]; then
    mv "$XSTARTUP" "${XSTARTUP}.bak"
fi

# Create new xstartup for Cinnamon/LMDE
cat > "$XSTARTUP" <<EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec /etc/X11/Xsession
EOF

chmod +x "$XSTARTUP"
chown "$REAL_USER:$REAL_USER" "$XSTARTUP"
log_success "Created $XSTARTUP"

# --- Step 4: Systemd Service ---
log_info "Step 4: Creating Systemd unit for VNC..."

SERVICE_FILE="/etc/systemd/system/vncserver@.service"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$REAL_USER
Group=$REAL_USER
WorkingDirectory=$REAL_HOME

PIDFile=$REAL_HOME/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 -localhost no :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vncserver@1.service
systemctl restart vncserver@1.service

if systemctl is-active --quiet vncserver@1.service; then
    log_success "VNC service (Display :1) is active and enabled."
else
    log_error "VNC service failed to start. Check 'journalctl -xeu vncserver@1.service'."
fi

# --- Step 5: Firewall ---
log_info "Step 5: Checking Firewall (UFW)..."
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        log_info "Allowing VNC port (5901) in UFW..."
        ufw allow 5901/tcp
        log_success "Port 5901 allowed."
    fi
fi

# --- Step 6: Summary ---
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       VNC Configuration Complete!           ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

IP_ADDRS=$(hostname -I | awk '{print $1}')
log_info "Connection Info:"
echo "---------------------------------------------"
echo -e "   IP Address:  ${YELLOW}$IP_ADDRS${NC}"
echo -e "   VNC Port:    ${YELLOW}5901${NC} (Display :1)"
echo -e "   Connect as:  ${GREEN}$IP_ADDRS:5901${NC}"
echo "---------------------------------------------"
echo ""
log_warn "Notes:"
echo "1. Use any VNC Viewer (VNC Connect, TigerVNC, etc.)."
echo "2. The virtual desktop resolution is currently set to 1920x1080."
echo "3. You can manage the service with: sudo systemctl status vncserver@1.service"
echo ""

exit 0
