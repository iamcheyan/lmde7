#!/bin/bash

# LMDE 7 Dotfiles & Terminal Environment Setup Script
# Automatically sets up Zsh, Powerlevel10k, Neovim, and Rust CLI tools
# Based on https://github.com/iamcheyan/Dotfiles

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
    log_warn "This script requires root privileges to install system dependencies."
    exec sudo "$0" "$@"
fi

clear
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   Dotfiles & Dev Environment Setup Helper   ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# --- Step 1: Install System Dependencies ---

log_info "Step 1: Installing system dependencies for Neovim & Treesitter..."
# Based on Dotfiles README requirements for Debian
apt update
apt install -y build-essential pkg-config cmake unzip clang libclang-dev curl git fontconfig

# --- Step 2: Clone and Initialize Dotfiles ---

REAL_USER=$SUDO_USER
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
DOTFILES_DIR="$REAL_HOME/Dotfiles"
REPO_URL="https://github.com/iamcheyan/Dotfiles.git"

log_info "Step 2: Syncing Dotfiles to $DOTFILES_DIR..."

if [ -d "$DOTFILES_DIR" ]; then
    log_warn "Dotfiles directory already exists."
    read -p "Do you want to update and re-run init.sh? [y/N]: " update_choice
    if [[ "$update_choice" =~ ^[yY]$ ]]; then
        cd "$DOTFILES_DIR" && sudo -u "$REAL_USER" git pull
    else
        log_info "Skipping clone/update."
    fi
else
    sudo -u "$REAL_USER" git clone "$REPO_URL" "$DOTFILES_DIR"
    log_success "Clone complete."
fi

# --- Step 3: Run init.sh ---

log_info "Step 3: Running Dotfiles init.sh..."

if [ -f "$DOTFILES_DIR/init.sh" ]; then
    cd "$DOTFILES_DIR"
    # Execute the init script as the real user
    # Note: init.sh will handle its own backups and plugin pulling
    sudo -u "$REAL_USER" bash ./init.sh
    log_success "Dotfiles initialization complete."
else
    log_error "init.sh not found in the Dotfiles repository!"
fi

# --- Step 4: Summary ---

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       Terminal Environment Ready!           ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Features installed:"
echo " - Zsh + Powerlevel10k (Autosuggestions, Syntax Highlighting)"
echo " - Neovim (LazyVim with AI assistant)"
echo " - Modern CLI tools (bat, rg, fzf, etc.)"
echo " - Meslo Nerd Font & Noto Serif CJK"
echo ""
echo "Next Steps:"
echo "1. Restart your terminal to activate Zsh."
echo "2. If prompted by P10K, complete the configuration wizard."
echo "3. Run 'nvim' to let LazyVim install its plugins."
echo ""
log_info "Enjoy your ultimate terminal experience!"

exit 0
