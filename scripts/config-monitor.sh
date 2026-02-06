#!/bin/bash
# OpenClaw Config Monitor - 配置文件监控与自愈

CONFIG_FILE="/Users/macmini-tracky/.openclaw/openclaw.json"
BACKUP_FILE="/Users/macmini-tracky/.openclaw/openclaw.json.bak"
LOG_FILE="/Users/macmini-tracky/.openclaw/logs/config-monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查配置是否有效
check_config() {
    if ! python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
        log "❌ Config invalid, restoring backup..."
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        log "✅ Backup restored"
        return 1
    fi
    return 0
}

# 检查 Gateway 是否运行
check_gateway() {
    if ! pgrep -f "openclaw-gateway" > /dev/null; then
        log "⚠️ Gateway not running, restarting..."
        cd /Users/macmini-tracky/.openclaw && openclaw gateway restart
        log "✅ Gateway restarted"
    fi
}

# 主循环
while true; do
    check_config
    check_gateway
    sleep 30
done
