#!/bin/bash
# OpenClaw Config Monitor - 配置文件监控与自愈（正确版）

CONFIG_FILE="/Users/macmini-tracky/.openclaw/openclaw.json"
BACKUP_FILE="/Users/macmini-tracky/.openclaw/openclaw.json.bak"
LOG_FILE="/Users/macmini-tracky/.openclaw/logs/config-monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查 Gateway 是否运行
check_gateway() {
    if pgrep -f "openclaw-gateway" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# 初始化：确保 Gateway 正常 + 创建备份
init() {
    log "🚀 Config monitor starting..."
    
    # 1. 确保 Gateway 正在运行
    if check_gateway; then
        log "✅ Gateway is running"
    else
        log "⚠️ Gateway not running, starting..."
        cd /Users/macmini-tracky/.openclaw && nohup openclaw gateway start > /dev/null 2>&1 &
        sleep 5
        if check_gateway; then
            log "✅ Gateway started"
        else
            log "❌ Gateway start failed"
            exit 1
        fi
    fi
    
    # 2. 创建带时间戳的备份
    TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
    TIMED_BACKUP="/Users/macmini-tracky/.openclaw/openclaw.json.bak.$TIMESTAMP"
    cp "$CONFIG_FILE" "$TIMED_BACKUP"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    log "📁 Backup created: $TIMED_BACKUP"
    
    # 3. 进入监控循环
    monitor_loop
}

# 监控循环
monitor_loop() {
    while true; do
        # 检查配置有效性
        if ! python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
            log "❌ Config invalid, restoring from backup..."
            cp "$BACKUP_FILE" "$CONFIG_FILE"
            log "✅ Config restored"
        fi
        
        # 检查 Gateway
        if ! check_gateway; then
            log "⚠️ Gateway not running, restarting..."
            cd /Users/macmini-tracky/.openclaw && nohup openclaw gateway start > /dev/null 2>&1 &
            sleep 5
            if check_gateway; then
                log "✅ Gateway restarted"
            else
                log "❌ Gateway restart failed"
            fi
        fi
        
        sleep 30
    done
}

# 启动
init
