#!/bin/bash

# Claude Code Notifier 卸载脚本
# 功能：移除 settings.json 中的 hooks 配置，并删除安装的文件

set -e

# 定义颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Claude Code Notifier 卸载脚本 ===${NC}"

# 1. 移除 settings.json 中的配置
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_PATH="$HOME/.claude/scripts/notify.sh"

if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${BLUE}正在从 ~/.claude/settings.json 中移除 hooks 配置...${NC}"

    # 使用 Python 安全地修改 JSON
    python3 -c "
import json
import os
import sys

settings_path = os.path.expanduser('~/.claude/settings.json')
script_path = os.path.expanduser('~/.claude/scripts/notify.sh')

if not os.path.exists(settings_path):
    print('配置文件不存在，跳过。')
    sys.exit(0)

try:
    with open(settings_path, 'r') as f:
        data = json.load(f)
except json.JSONDecodeError:
    print('错误: settings.json 格式无效，无法自动修改。请手动检查。')
    sys.exit(1)

modified = False

# 1. 移除 Hooks
if 'hooks' in data:
    events = ['PermissionRequest', 'Stop']

    for event in events:
        if event in data['hooks']:
            new_hooks = []
            for matcher_group in data['hooks'][event]:
                # 检查该组 hooks 中是否包含我们的脚本
                keep_group = True
                if matcher_group.get('matcher') == '*':
                    filtered_hooks = []
                    for h in matcher_group.get('hooks', []):
                        if script_path in h.get('command', ''):
                            print(f'  - 移除 {event} hook')
                            modified = True
                        else:
                            filtered_hooks.append(h)

                    # 如果过滤后该组还有其他 hook，保留该组
                    if filtered_hooks:
                        matcher_group['hooks'] = filtered_hooks
                        new_hooks.append(matcher_group)
                    # 如果过滤后为空，则不添加到 new_hooks (即删除该组)
                else:
                    new_hooks.append(matcher_group)

            # 如果该事件下还有 hook 组，更新；否则删除该事件键
            if new_hooks:
                data['hooks'][event] = new_hooks
            else:
                del data['hooks'][event]

# 2. 移除 Commands (/notifier)
if 'commands' in data:
    if 'notifier' in data['commands']:
        del data['commands']['notifier']
        print('  - 移除 /notifier 命令')
        modified = True
        # 如果 commands 为空，可以选择删除 (可选)
        if not data['commands']:
            del data['commands']

if modified:
    with open(settings_path, 'w') as f:
        json.dump(data, f, indent=2)
    print('✓ 配置文件已更新')
else:
    print('未找到相关配置，无需移除。')
"
else
    echo -e "${YELLOW}未找到配置文件: $SETTINGS_FILE${NC}"
fi

# 2. 删除文件
INSTALL_DIR="$HOME/.claude/scripts"
ASSETS_DIR="$HOME/.claude/assets"
CONFIG_FILE="$HOME/.claude/notifier.conf"

echo -e "${BLUE}正在删除安装文件...${NC}"

if [ -f "$INSTALL_DIR/notify.sh" ]; then
    rm "$INSTALL_DIR/notify.sh"
    echo -e "${GREEN}✓ 已删除脚本: $INSTALL_DIR/notify.sh${NC}"
fi

if [ -f "$INSTALL_DIR/toggle.sh" ]; then
    rm "$INSTALL_DIR/toggle.sh"
    echo -e "${GREEN}✓ 已删除脚本: $INSTALL_DIR/toggle.sh${NC}"
fi

if [ -f "$CONFIG_FILE" ]; then
    read -p "是否删除配置文件 ($CONFIG_FILE)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$CONFIG_FILE"
        echo -e "${GREEN}✓ 已删除配置文件${NC}"
    else
        echo -e "已保留配置文件。"
    fi
fi

if [ -f "$ASSETS_DIR/logo.png" ]; then
    read -p "是否删除图标资源 ($ASSETS_DIR/logo.png)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$ASSETS_DIR/logo.png"
        echo -e "${GREEN}✓ 已删除图标资源${NC}"

        # 尝试删除空目录
        rmdir "$ASSETS_DIR" 2>/dev/null || true
    else
        echo -e "已保留图标资源。"
    fi
fi

# 尝试删除脚本目录（如果为空）
rmdir "$INSTALL_DIR" 2>/dev/null || true

echo -e "${BLUE}=== 卸载完成 ===${NC}"
