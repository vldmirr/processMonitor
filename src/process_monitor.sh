#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"
STATE_FILE="/var/run/process_monitor.state"

# Функция для логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    logger "ProcessMonitor: $1"
}

log "DEBUG: Script started"

# Проверяем существование STATE_FILE
if [ ! -f "$STATE_FILE" ]; then
    log "DEBUG: State file created"
    echo "unknown" > "$STATE_FILE"
fi

# Проверяем процесс
if pgrep -x "$PROCESS_NAME" > /dev/null; then
    log "DEBUG: Process $PROCESS_NAME is running"
    CURRENT_STATE="running"
else
    log "DEBUG: Process $PROCESS_NAME is NOT running"
    CURRENT_STATE="stopped"
fi

# Читаем предыдущее состояние
PREVIOUS_STATE=$(cat "$STATE_FILE")
log "DEBUG: Previous state: $PREVIOUS_STATE, Current state: $CURRENT_STATE"

# Если процесс запущен
if [ "$CURRENT_STATE" = "running" ]; then
    log "DEBUG: Sending monitoring request"
    
    # Пробуем отправить запрос
    if curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: ProcessMonitor/1.0" "$URL" > /dev/null 2>&1; then
        log "DEBUG: Monitoring request successful"
    else
        log "ERROR: Monitoring server unavailable or curl failed"
    fi
    
    # Проверяем перезапуск
    if [ "$PREVIOUS_STATE" = "stopped" ] && [ "$CURRENT_STATE" = "running" ]; then
        log "INFO: Process '$PROCESS_NAME' was restarted"
    fi
fi

# Сохраняем состояние
echo "$CURRENT_STATE" > "$STATE_FILE"
log "DEBUG: Script finished"
                             