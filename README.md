# LMDE 7 / Debian 一键初始化脚本集 (One-Click Setup Scripts)

本项目是专为 **LMDE 7 (Linux Mint Debian Edition)** 打造的一键配置脚本集合。旨在帮助用户在系统安装完成后，快速完成日常开发与办公环境的配置，涵盖系统性能优化、远程办公、软件生态以及容灾备份。

## 🚀 脚本概览

| 脚本名称 | 功能描述 | 核心特性 |
| :--- | :--- | :--- |
| `setup_software.sh` | **核心软件初始化** | 清除冗余、安装字体、配置 **Flatpak** (Chrome, VS Code, QQ, WeChat 等) |
| `setup_grub_btrfs.sh` | **Btrfs 容灾全家桶** | 集成 Timeshift + grub-btrfs + autosnap，实现 **Apt 更新前自动快照** |
| `setup_ssh.sh` | **SSH 一键开启** | 自动安装、防火墙策略、显示连接 IP |
| `setup_rdp.sh` | **RDP 远程桌面** | 自动配置 XRDP、解决 Cinnamon 桌面冲突、消除 Polkit 验证弹窗 |
| `setup_vnc.sh` | **VNC 虚拟桌面** | 基于 TigerVNC，实现 5901 端口的图形化远程访问 |
| `setup_hibernate.sh` | **休眠功能修复** | 检查 Swap 分区 UUID、配置 GRUB 与 initramfs、开启菜单选项 |
| `setup_disable_wakeup.sh` | **防止休眠自动重启** | 禁用导致系统休眠后立即自动唤醒的 ACPI 设备 |
| `setup_rime.sh` | **Rime 输入法** | 自动安装 Fcitx5-Rime、Lua 插件及个人 XSB+日语配置 |
| `setup_dotfiles.sh` | **终端开发环境** | 一键克隆 Dotfiles，配置 Zsh (P10k) + Neovim (LazyVim) + Rust 工具链 |

---

## 🛠 使用方法

### 1. 克隆项目
```bash
sudo apt update && sudo apt install git -y
git clone https://github.com/iamcheyan/lmde7.git
cd lmde7
```

### 2. 运行总控脚本 (推荐)
```bash
chmod +x setup.sh
./setup.sh
```
该脚本提供交互式菜单，您可以根据数字选择需要安装的任务。

---

## 📝 详细功能说明

### 🛡️ Btrfs 自动防御系统 (`setup_grub_btrfs.sh`)
本脚本构建了一个完整的数据保护链：
1.  **Timeshift**: 基础快照工具。
2.  **timeshift-autosnap-apt**: 监听 `apt` 操作。每次执行安装/更新指令前，系统会自动创建快照。
3.  **grub-btrfs**: 将快照注入 GRUB 启动菜单。
4.  **grub-btrfsd**: 后台守护进程，实时同步快照变化到引导菜单。

### 🎨 软件生态优化 (`setup_software.sh`)
*   **去臃肿**: 自动移除 LibreOffice (Apt), Thunderbird, Rhythmbox 等。
*   **Flatpak 优先**: 常用大型客户端（QQ、微信、Spotify 等）均通过 Flatpak 安装，零依赖、易更新、不污染系统根目录。
*   **4K 适配**: 专门针对 4K 屏幕安装了 `grub2-theme-mint-2k` 视觉主题。

### 🖥️ 远程桌面优化 (`setup_rdp.sh`)
*   自动解决 XRDP 与系统本地桌面的会话冲突。
*   自动修复进入桌面后频繁弹出的“设备颜色管理”授权弹窗。

---

## ⚠️ 注意事项
1.  **权限**: 所有脚本均需 `sudo` 权限运行，脚本内会自动提示提权。
2.  **休眠**: 使用 `setup_hibernate.sh` 之前，请通过 `swapon --show` 确认你的 Swap 分区大小大于等于内存大小。
3.  **Btrfs**: `setup_grub_btrfs.sh` 仅适用于根目录 (`/`) 安装在 Btrfs 分区的文件系统。

## 💡 贡献建议
如果你有其他好用的 LMDE 优化建议（如 Zsh 配置、Docker 环境一键安装等），欢迎提交 Issue 或 Pull Request。
