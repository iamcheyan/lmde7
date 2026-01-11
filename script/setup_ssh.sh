#!/bin/bash

# LMDE 7 / Debian SSH Configuration Script
# One-click SSH setup and verification helper

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

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}      SSH One-Click Configuration Helper     ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# --- Step 1: Install OpenSSH Server ---
log_info "Step 1: Checking OpenSSH Server installation..."

if dpkg -l | grep -q openssh-server; then
    log_success "openssh-server is already installed."
else
    log_info "openssh-server not found. Installing..."
    apt-get update
    apt-get install -y openssh-server
    if [ $? -eq 0 ]; then
        log_success "openssh-server installed successfully."
    else
        log_error "Failed to install openssh-server. Please check your internet connection and apt sources."
        exit 1
    fi
fi

# --- Step 2: Service Status ---
log_info "Step 2: Checking SSH service status..."

if systemctl is-active --quiet ssh; then
    log_success "SSH service is running."
else
    log_info "SSH service is not running. Starting..."
    systemctl start ssh
    log_success "SSH service started."
fi

if systemctl is-enabled --quiet ssh; then
    log_success "SSH service is enabled to start on boot."
else
    log_info "SSH service is not enabled on boot. Enabling..."
    systemctl enable ssh
    log_success "SSH service enabled."
fi

# --- Step 3: Firewall Configuration ---
log_info "Step 3: Checking Firewall (UFW) status..."

if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        log_info "UFW is active. Checking if SSH port (22/tcp) is allowed..."
        if ufw status | grep -q "22/tcp" || ufw status | grep -q "SSH"; then
            log_success "SSH port is already allowed in UFW."
        else
            log_info "Allowing SSH in UFW..."
            ufw allow ssh
            log_success "SSH port allowed."
        fi
    else
        log_info "UFW is inactive. No firewall changes needed."
    fi
else
    log_warn "UFW is not installed. Skipping firewall check."
fi

# --- Step 4: Configuration Check ---
log_info "Step 4: Checking SSH Configuration..."

SSH_CONFIG="/etc/ssh/sshd_config"

# Check if PasswordAuthentication is explicitly set to no
if grep -q "^PasswordAuthentication no" "$SSH_CONFIG"; then
    log_warn "Password authentication is currently DISABLED in $SSH_CONFIG."
    read -p "Do you want to enable password authentication? [y/N]: " choice
    if [[ "$choice" =~ ^[yY]$ ]]; then
        sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$SSH_CONFIG"
        log_success "Password authentication enabled. Restarting SSH..."
        systemctl restart ssh
    fi
fi

# --- Step 5: Connection Information ---
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       Configuration Complete!               ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# Get IP addresses (excluding loopback)
IP_ADDRS=$(hostname -I)
USER_NAME=$(whoami)
PRIMARY_IP=$(echo $IP_ADDRS | awk '{print $1}')

log_info "Your SSH connection details:"
echo "---------------------------------------------"
echo -e "   Current User: ${YELLOW}$USER_NAME${NC}"
echo -e "   IP Addresses: ${YELLOW}$IP_ADDRS${NC}"
echo -e "   Connect via:  ${GREEN}ssh $USER_NAME@$PRIMARY_IP${NC}"
echo "---------------------------------------------"
echo ""

log_success "SSH is now fully configured and running."
echo "You can check service status with: systemctl status ssh"
echo "You can view login logs with:      journalctl -u ssh -f"
echo ""

exit 0
