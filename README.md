# Claude Code Notifier 🔔

**不错过任何一次确认，不浪费每一秒等待。**

为 Claude Code (Anthropic CLI) 添加原生系统通知、声音提示和自动终端激活功能。

![Demo](assets/demo.png)

## ✨ 功能特性

*   **🔔 智能通知**：区分“任务完成”(Stop) 和 “请求权限”(PermissionRequest)。
*   **🔊 声音提示**：
    *   需要确认时播放醒目的提示音。
    *   任务完成时播放清脆的完成音。
*   **🚀 自动跳转 (macOS)**：当 Claude 需要你确认权限时，自动将终端窗口带到前台（Focus），不再因为切屏看网页而忘记确认。
*   **🐧 Linux 支持**：完美支持 Linux 桌面环境 (GNOME, KDE 等)，使用 `notify-send` 和原生音频系统。
*   **⌨️ 快捷命令**：直接在 Claude 中使用 `/notifier` 命令控制通知开关。
*   **⚙️ 灵活配置**：支持配置文件 `notifier.conf`，轻松修改声音、行为和图标，升级不丢失配置。
*   **🖥️ 多终端支持**：支持 iTerm2, VS Code, Cursor, Warp, Terminal.app 以及 JetBrains 全家桶。

## 📦 安装

### 一键安装

下载本项目并运行安装脚本：

```bash
git clone https://github.com/your-username/claude-code-notifier.git
cd claude-code-notifier
chmod +x install.sh
./install.sh
```

脚本会自动：
1.  安装核心脚本和配置文件到 `~/.claude/` 目录。
2.  自动修改 `settings.json` 添加 Hooks 和 Slash Command。
3.  **macOS**: 自动检测并尝试安装 `terminal-notifier` (推荐)。
4.  **Linux**: 检查 `libnotify` 等依赖。

### 依赖说明

*   **macOS**: 推荐安装 `terminal-notifier` 以获得最佳体验（支持图标和点击跳转）。如果没有，脚本会自动回退到原生通知。
*   **Linux**: 需要 `libnotify-bin` (Debian/Ubuntu) 或 `libnotify` (Arch) 以及音频播放器 (`paplay` 或 `aplay`)。

## 🎮 使用方法

### 基础使用
安装完成后无需额外操作。当你使用 Claude Code 时：
*   **权限请求**：会弹出警告图标通知 + 播放提示音 + (macOS) 自动激活终端。
*   **任务完成**：会弹出完成图标通知 + 播放完成音。

### Slash Commands (快捷命令)
你可以在 Claude Code 的对话框中直接控制通知：

*   `/notifier status` - 查看当前通知状态
*   `/notifier off` - 关闭通知（例如在会议演示时）
*   `/notifier on` - 重新开启通知

## ⚙️ 配置与自定义

### 修改配置
安装后，配置文件位于 `~/.claude/notifier.conf`。你可以修改它来：
*   更换提示音效文件路径。
*   开启/关闭自动激活终端功能。
*   自定义通知标题文字。

### 自定义图标
只需将你的图片命名为 `logo.png` 并放入 `~/.claude/assets/` 目录即可生效。
*(安装包内 `assets/` 目录下的 `logo.png` 会在安装时自动复制过去)*

> **注意 (macOS)**：macOS 高版本系统（如 macOS 12+）由于系统限制，通知可能无法显示自定义 Logo，而是显示终端应用的图标。这是 macOS 系统层面的行为，无法绕过。

## 🗑️ 卸载

如果不想要了，运行卸载脚本即可清理得干干净净：

```bash
./uninstall.sh
```

它会自动从 `settings.json` 中移除所有相关配置，并删除安装的文件。

## 🤝 贡献

欢迎提交 Issue 和 PR 适配更多的终端类型或 Linux 发行版。

## License

MIT
