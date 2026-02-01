#!/bin/bash

# LMDE 7 一键初始化总控脚本 (Master Setup Menu)
# Author: iamcheyan

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the script directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$BASE_DIR/script"

# Helper Function: Run sub-script
run_task() {
    local script_name=$1
    if [ -f "$SCRIPT_DIR/$script_name" ]; then
        chmod +x "$SCRIPT_DIR/$script_name"
        bash "$SCRIPT_DIR/$script_name"
    else
        echo -e "${RED}[错误]${NC} 找不到脚本: $script_name"
    fi
}

show_menu() {
    clear
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${CYAN}   LMDE 7 / Debian 一键初始化总控工具        ${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo ""
    echo -e "${PURPLE}[ 核心配置 ]${NC}"
    echo -e "  1) 基础软件初始化 (Software & Flatpak)"
    echo -e "  2) 极致终端环境 (Dotfiles, Zsh, Neovim)"
    echo -e "  3) Rime 输入法 (新声笔 XSB & 日语)"
    echo ""
    echo -e "${PURPLE}[ 系统及休眠 ]${NC}"
    echo -e "  4) Btrfs 自动快照 (grub-btrfs/Timeshift)"
    echo -e "  5) 开启休眠功能 (Swap UUID & GRUB)"
    echo -e "  6) 修复休眠自动重启 (Disable ACPI Wake)"
    echo ""
    echo -e "${PURPLE}[ 远程连接 ]${NC}"
    echo -e "  7) 开启 SSH 服务"
    echo -e "  8) 开启 RDP 远程桌面 (xrdp)"
    echo -e "  9) 开启 VNC 虚拟桌面"
    echo ""
    echo -e "  s) 查看当前服务状态 (Status Check)"
    echo -e "  a) 一键运行全套推荐配置 (1, 2, 3, 4)"
    echo -e "  q) 退出 (Quit)"
    echo ""
    echo -e "${CYAN}=============================================${NC}"
}

while true; do
    show_menu
    read -p "请输入选项数字 [1-9, a, q]: " choice

    case $choice in
        1) run_task "setup_software.sh" ;;
        2) run_task "setup_dotfiles.sh" ;;
        3) run_task "setup_rime.sh" ;;
        4) run_task "setup_grub_btrfs.sh" ;;
        5) run_task "setup_hibernate.sh" ;;
        6) run_task "setup_disable_wakeup.sh" ;;
        7) run_task "setup_ssh.sh" ;;
        8) run_task "setup_rdp.sh" ;;
        9) run_task "setup_vnc.sh" ;;
        [sS]) run_task "check_status.sh" ;;
        [aA])
            echo -e "${YELLOW}>> 开始执行推荐初始化全家桶...${NC}"
            run_task "setup_software.sh"
            run_task "setup_dotfiles.sh"
            run_task "setup_rime.sh"
            run_task "setup_grub_btrfs.sh"
            echo -e "${GREEN}>> 推荐配置执行完毕！${NC}"
            read -p "按回车键返回菜单..."
            ;;
        [qQ])
            echo -e "${GREEN}感谢使用，再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}非法输入，请重试。${NC}"
            sleep 1
            ;;
    esac

    echo ""
    read -p "任务执行完毕。按回车键返回主菜单..."
done
