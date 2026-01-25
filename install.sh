#!/bin/bash

set -e

# 定义颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Claude Code Notifier 安装脚本 ===${NC}"

# 1. 准备目录
INSTALL_DIR="$HOME/.claude/scripts"
ASSETS_DIR="$HOME/.claude/assets"
mkdir -p "$INSTALL_DIR"
mkdir -p "$ASSETS_DIR"
echo -e "${GREEN}✓ 创建安装目录: $INSTALL_DIR 和 $ASSETS_DIR${NC}"

# 2. 复制脚本和资源
# 假设脚本与 install.sh 在同一仓库结构中
SCRIPT_SOURCE="$(dirname "$0")/scripts/notify.sh"
TOGGLE_SOURCE="$(dirname "$0")/scripts/toggle.sh"
CONF_SOURCE="$(dirname "$0")/scripts/notifier.conf"
LOGO_SOURCE="$(dirname "$0")/assets/logo.png"

if [ ! -f "$SCRIPT_SOURCE" ]; then
    echo -e "${YELLOW}正在从当前目录查找 scripts/notify.sh...${NC}"
    if [ -f "./scripts/notify.sh" ]; then
        SCRIPT_SOURCE="./scripts/notify.sh"
        TOGGLE_SOURCE="./scripts/toggle.sh"
        CONF_SOURCE="./scripts/notifier.conf"
        LOGO_SOURCE="./assets/logo.png"
    else
        echo "错误: 找不到 scripts/notify.sh"
        exit 1
    fi
fi

cp "$SCRIPT_SOURCE" "$INSTALL_DIR/notify.sh"
chmod +x "$INSTALL_DIR/notify.sh"

if [ -f "$TOGGLE_SOURCE" ]; then
    cp "$TOGGLE_SOURCE" "$INSTALL_DIR/toggle.sh"
    chmod +x "$INSTALL_DIR/toggle.sh"
    echo -e "${GREEN}✓ 开关脚本 (toggle.sh) 已安装${NC}"
fi

echo -e "${GREEN}✓ 核心脚本已安装并赋予执行权限${NC}"

# 安装配置文件 (不覆盖已存在的配置)
CONF_DEST="$HOME/.claude/notifier.conf"
if [ ! -f "$CONF_DEST" ]; then
    if [ -f "$CONF_SOURCE" ]; then
        cp "$CONF_SOURCE" "$CONF_DEST"
        echo -e "${GREEN}✓ 配置文件已安装到: $CONF_DEST${NC}"
    else
        echo -e "${YELLOW}警告: 找不到默认配置文件，跳过安装。${NC}"
    fi
else
    echo -e "${YELLOW}提示: 配置文件已存在，跳过覆盖以保留你的设置。${NC}"
fi

# 复制 Logo (如果存在)
if [ -f "$LOGO_SOURCE" ]; then
    cp "$LOGO_SOURCE" "$ASSETS_DIR/logo.png"
    echo -e "${GREEN}✓ Logo 图标已安装${NC}"
else
    echo -e "${YELLOW}提示: 未找到 assets/logo.png，将使用默认图标。${NC}"
    echo -e "      如果你想要自定义图标，请将图片放入 assets/logo.png 并重新运行安装。"
fi

# 3. 检查依赖 (terminal-notifier 或 libnotify)
OS_TYPE=$(uname -s)

if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS: 检查 terminal-notifier
    if ! command -v terminal-notifier &> /dev/null; then
        if command -v brew &> /dev/null; then
            echo -e "${YELLOW}未检测到 terminal-notifier，正在尝试通过 Homebrew 自动安装...${NC}"
            if brew install terminal-notifier; then
                echo -e "${GREEN}✓ terminal-notifier 安装成功${NC}"
            else
                echo -e "${YELLOW}自动安装失败，将使用原生通知。${NC}"
                echo -e "推荐手动安装以获得最佳体验: ${BLUE}brew install terminal-notifier${NC}"
            fi
        else
            echo -e "${YELLOW}提示: 未检测到 terminal-notifier。${NC}"
            echo -e "      脚本将使用 macOS 原生通知（无副标题，无法点击跳转）。"
            echo -e "      推荐安装以获得最佳体验: ${BLUE}brew install terminal-notifier${NC}"
        fi
    else
        echo -e "${GREEN}✓ 检测到 terminal-notifier${NC}"
    fi
elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Linux: 检查 notify-send
    if ! command -v notify-send &> /dev/null; then
        echo -e "${YELLOW}提示: 未检测到 notify-send。${NC}"
        echo -e "      请安装 libnotify-bin (Debian/Ubuntu) 或 libnotify (Arch/Fedora) 以启用通知。"
        echo -e "      例如: ${BLUE}sudo apt install libnotify-bin${NC}"
    else
        echo -e "${GREEN}✓ 检测到 notify-send${NC}"
    fi

    # Linux: 检查声音播放器
    if ! command -v paplay &> /dev/null && ! command -v aplay &> /dev/null; then
        echo -e "${YELLOW}提示: 未检测到 paplay (PulseAudio) 或 aplay (ALSA)。可能无法播放提示音。${NC}"
    fi
fi

# 4. 修改 settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
echo -e "${BLUE}正在配置 ~/.claude/settings.json ...${NC}"

# 使用 Python 安全地修改 JSON
python3 -c "
import json
import os
import sys

settings_path = os.path.expanduser('~/.claude/settings.json')
script_path = os.path.expanduser('~/.claude/scripts/notify.sh')

# 确保文件存在
if not os.path.exists(settings_path):
    print(f'创建新的配置文件: {settings_path}')
    data = {}
else:
    try:
        with open(settings_path, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError:
        print('错误: settings.json 格式无效，已备份并创建新文件')
        os.rename(settings_path, settings_path + '.bak')
        data = {}

# 确保 hooks 结构存在
if 'hooks' not in data:
    data['hooks'] = {}

# 定义我们要添加的 hook 配置
# 注意：我们这里覆盖或添加到现有的列表中
target_hooks = {
    'PermissionRequest': {
        'command': f'CLAUDE_TOOL_NAME=\"PermissionRequest\" {script_path}',
        'type': 'command'
    },
    'Stop': {
        'command': f'CLAUDE_TOOL_NAME=\"Stop\" {script_path}',
        'type': 'command'
    }
}

for event, hook_config in target_hooks.items():
    if event not in data['hooks']:
        data['hooks'][event] = []

    # 检查是否已经存在类似的 hook (避免重复添加)
    exists = False
    for matcher_group in data['hooks'][event]:
        if matcher_group.get('matcher') == '*':
            for h in matcher_group.get('hooks', []):
                if script_path in h.get('command', ''):
                    exists = True
                    print(f'  - {event} hook 已存在，跳过')
                    break
        if exists: break

    if not exists:
        # 添加新的 hook
        new_entry = {
            'matcher': '*',
            'hooks': [hook_config]
        }
        data['hooks'][event].append(new_entry)
        print(f'  - 已添加 {event} hook')


# 写回文件
with open(settings_path, 'w') as f:
    json.dump(data, f, indent=2)
"


# 5. 配置 Slash Command (via Markdown)
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"
NOTIFIER_MD="$COMMANDS_DIR/notifier.md"

echo -e "${BLUE}正在配置 /notifier 命令...${NC}"
cat > "$NOTIFIER_MD" <<EOF
---
description: Control Claude Code desktop notifications
---

# Notifier Control

此命令用于管理 Claude Code 的桌面通知设置。你可以开启或关闭权限请求时的弹窗通知和提示音，或者查看当前状态。

## Usage

\`\`\`bash
$INSTALL_DIR/toggle.sh [on|off|status]
\`\`\`
EOF
echo -e "${GREEN}✓ 命令定义已创建: $NOTIFIER_MD${NC}"

echo -e "${GREEN}✓ 配置完成！${NC}"
echo -e "${BLUE}=== 安装成功 ===${NC}"
echo -e "现在，当 Claude Code 完成任务或需要权限时，你将收到系统通知。"
