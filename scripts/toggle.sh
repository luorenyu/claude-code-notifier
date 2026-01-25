#!/bin/bash

# Claude Code Notifier Toggle Tool
# 功能：用于通过 Slash Command (/notifier) 切换通知开关
# 用法：/notifier [on|off|status]

CONFIG_FILE="$HOME/.claude/notifier.conf"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 确保配置文件存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 错误: 找不到配置文件 $CONFIG_FILE"
    exit 1
fi

# 读取当前状态函数
get_status() {
    # 简单的 grep 检查，假设 true/false 是小写
    if grep -q "ACTIVATE_ON_PERMISSION=true" "$CONFIG_FILE"; then
        echo "on"
    else
        echo "off"
    fi
}

# 修改配置函数
set_config() {
    local key="$1"
    local value="$2"

    # 使用 sed 替换配置
    # 注意：这里假设配置项是 key=value 格式且每行一个
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed
        sed -i '' "s/^$key=.*/$key=$value/" "$CONFIG_FILE"
    else
        # Linux sed
        sed -i "s/^$key=.*/$key=$value/" "$CONFIG_FILE"
    fi
}

ACTION="${1:-status}"

case "$ACTION" in
    "on")
        set_config "ACTIVATE_ON_PERMISSION" "true"
        # 同时开启 Stop 通知吗？暂时只控制 PermissionRequest 这个最核心的
        # set_config "ACTIVATE_ON_STOP" "true"
        echo -e "${GREEN}🔔 通知已开启${NC}"
        echo "Claude 在请求权限时将弹出通知并激活终端。"
        ;;
    "off")
        set_config "ACTIVATE_ON_PERMISSION" "false"
        set_config "ACTIVATE_ON_STOP" "false"
        echo -e "${RED}🔕 通知已关闭${NC}"
        echo "Claude 将不再发送弹窗通知。"
        ;;
    "status")
        STATUS=$(get_status)
        if [ "$STATUS" == "on" ]; then
            echo -e "当前状态: ${GREEN}开启 (ON)${NC}"
        else
            echo -e "当前状态: ${RED}关闭 (OFF)${NC}"
        fi

        # 显示 Focus Mode 状态
        if grep -q "RESPECT_FOCUS_MODE=true" "$CONFIG_FILE"; then
            echo -e "Focus Mode: ${GREEN}开启 (遵循勿扰)${NC}"
        else
            echo -e "Focus Mode: ${RED}关闭 (强制通知)${NC}"
        fi

        echo "使用 '/notifier on' 开启，'/notifier off' 关闭。"
        echo "使用 '/notifier focus [on|off]' 设置勿扰模式策略。"
        ;;
    "focus")
        SUB_ACTION="${2:-status}"
        if [[ "$SUB_ACTION" == "on" ]]; then
            set_config "RESPECT_FOCUS_MODE" "true"
            echo -e "${GREEN}Focus Mode 策略已开启${NC}"
            echo "Claude 将尊重系统的勿扰模式设置 (不发出声音或弹窗)。"
        elif [[ "$SUB_ACTION" == "off" ]]; then
            set_config "RESPECT_FOCUS_MODE" "false"
            echo -e "${RED}Focus Mode 策略已关闭${NC}"
            echo "Claude 将无视勿扰模式，强制发送通知。"
        else
            if grep -q "RESPECT_FOCUS_MODE=true" "$CONFIG_FILE"; then
                echo -e "Focus Mode 策略: ${GREEN}开启${NC}"
            else
                echo -e "Focus Mode 策略: ${RED}关闭${NC}"
            fi
        fi
        ;;
    *)
        echo "用法: /notifier [on|off|status]"
        exit 1
        ;;
esac
