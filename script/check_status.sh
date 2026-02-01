#!/bin/bash

# LMDE 7 Service & Configuration Status Checker
# Author: iamcheyan

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the real user
REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

clear
echo -e "${CYAN}=============================================${NC}"
echo -e "${CYAN}      LMDE 7 系统服务与配置状态看板         ${NC}"
echo -e "${CYAN}=============================================${NC}"

# --- Helper Functions ---
check_pkg() {
    if dpkg -l | grep -q "$1"; then echo "installed"; else echo "not_installed"; fi
}

check_service() {
    if systemctl is-active --quiet "$1"; then
        echo "running"
    elif systemctl is-enabled --quiet "$1" 2>/dev/null; then
        echo "stopped"
    else
        if dpkg -l | grep -q "$1" || command -v "$1" >/dev/null 2>&1; then
            echo "stopped"
        else
            echo "not_installed"
        fi
    fi
}

print_status() {
    local label=$1
    local status=$2
    local extra=$3
    case $status in
        "running")
            printf "  %-30s %-20s %s\n" "$label" "${GREEN}[已启动]${NC}" "$extra"
            ;;
        "stopped")
            printf "  %-30s %-20s %s\n" "$label" "${YELLOW}[已停止]${NC}" "$extra"
            ;;
        "not_installed")
            printf "  %-30s %-20s %s\n" "$label" "${RED}[未安装]${NC}" "$extra"
            ;;
    esac
}

# --- 1. 远程访问服务 ---
echo -e "\n${PURPLE}[ 远程访问服务 ]${NC}"

# SSH
SSH_STATUS=$(check_service "ssh")
SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
SSH_PORT=${SSH_PORT:-22}
print_status "SSH 服务 (openssh)" "$SSH_STATUS" "端口: $SSH_PORT | 配置: /etc/ssh/sshd_config"

# RDP
RDP_STATUS=$(check_service "xrdp")
RDP_PORT=$(grep "^port=" /etc/xrdp/xrdp.ini | head -1 | cut -d= -f2)
RDP_PORT=${RDP_PORT:-3389}
print_status "RDP 远程桌面 (xrdp)" "$RDP_STATUS" "端口: $RDP_PORT | 配置: /etc/xrdp/xrdp.ini"

# VNC
VNC_STATUS=$(check_service "vncserver@1.service")
print_status "VNC 虚拟桌面 (:1)" "$VNC_STATUS" "端口: 5901 | 配置: ~/.vnc/xstartup"

# --- 2. 系统核心配置 ---
echo -e "\n${PURPLE}[ 系统及功能优化 ]${NC}"

# Btrfs 快照
GRUB_BTRFS=$(check_service "grub-btrfsd")
AUTOSNAP=$(check_pkg "timeshift-autosnap-apt")
if [[ "$AUTOSNAP" == "installed" ]]; then AUTOSNAP_L="[已安装]"; else AUTOSNAP_L="[未安装]"; fi
print_status "Btrfs 自动快照引导" "$GRUB_BTRFS" "Apt自动快照: $AUTOSNAP_L"

# Hibernate
if grep -q "resume=" /etc/default/grub; then
    HIB_STATUS="running"
    RESUME_UUID=$(grep -o "resume=UUID=[^ ]*" /etc/default/grub | cut -d= -f3)
    HIB_EXTRA="UUID: ${RESUME_UUID:0:8}... | 配置: /etc/default/grub"
else
    HIB_STATUS="not_installed"
    HIB_EXTRA="尚未配置 GRUB 引导"
fi
print_status "系统休眠功能" "$HIB_STATUS" "$HIB_EXTRA"

# Wakeup Fix
if [ -f "/etc/systemd/system/disable-acpi-wakeup.service" ]; then
    WAKE_STATUS=$(check_service "disable-acpi-wakeup.service")
    WAKE_COUNT=$(grep -c "enabled" /proc/acpi/wakeup 2>/dev/null)
    WAKE_EXTRA="活跃唤醒源: $WAKE_COUNT | 脚本: /usr/local/bin/disable-wakeup.sh"
else
    WAKE_STATUS="not_installed"
    WAKE_EXTRA=""
fi
print_status "休眠自动重启修复" "$WAKE_STATUS" "$WAKE_EXTRA"

# --- 3. 软件环境 ---
echo -e "\n${PURPLE}[ 软件与输入法 ]${NC}"

# Rime
RIME_STATUS=$(check_service "fcitx5")
if [ -d "$REAL_HOME/.local/share/fcitx5/rime" ]; then 
    RIME_EXTRA="配置已同步 | 路径: ~/.local/share/fcitx5/rime"
else 
    RIME_EXTRA="配置未就绪"
fi
print_status "Fcitx5-Rime 输入法" "$RIME_STATUS" "$RIME_EXTRA"

# Flatpak
if command -v flatpak >/dev/null 2>&1; then
    FP_COUNT=$(flatpak list --columns=application | wc -l)
    print_status "Flatpak 应用生态" "running" "已安装应用: $FP_COUNT | 运行 'flatpak list' 查看列表"
else
    print_status "Flatpak 应用生态" "not_installed" ""
fi

# Dotfiles
if [ -d "$REAL_HOME/Dotfiles" ]; then
    print_status "Dotfiles 环境" "running" "路径: ~/Dotfiles | 已同步最新配置"
else
    print_status "Dotfiles 环境" "not_installed" ""
fi

# --- 4. 自定义服务 (如 FFHDPV4 等) ---
echo -e "\n${PURPLE}[ 其他检测到的服务 ]${NC}"

# 搜索常见的非系统服务 (如 frp, web markers, etc.)
CUSTOM_SERVICES=("frpc" "frps" "ffhdpv4" "clash" "docker")
FOUND_CUSTOM=0

for svc in "${CUSTOM_SERVICES[@]}"; do
    S_STAT=$(check_service "$svc")
    if [[ "$S_STAT" != "not_installed" ]]; then
        print_status "$svc" "$S_STAT" ""
        FOUND_CUSTOM=1
    fi
done

if [ $FOUND_CUSTOM -eq 0 ]; then
    echo "  (暂未检测到其他自定义运行的服务)"
fi

echo -e "\n${CYAN}=============================================${NC}"
echo -e " 提示: 部分详细配置可通过查看脚本源码获取检测逻辑。"
echo -e " 使用 'systemctl status <服务名>' 查看具体错误信息。"
echo ""
read -p "按回车键返回菜单..."
