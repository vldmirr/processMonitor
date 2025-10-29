#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
MONITORING_URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"
STATE_FILE="/var/run/process_monitor.state"
CURRENT_STATE=""

#логирование
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

#проверки процесса
check() {
    if pgrep -x "$PROCESS_NAME" > /dev/null; then
        echo "running"
    else
        echo "stopped"
    fi
}

#отправки запроса
sendReq() {
    local response_code
    
    # Отправляем HTTPS запрос и получаем код ответа
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: ProcessMonitor/1.0" "$MONITORING_URL" 2>/dev/null)
    
    if [ "$response_code" -eq 200 ] || [ "$response_code" -eq 201 ]; then
        return 0
    else
        log "ERROR: Monitoring server unavailable. HTTP code: $response_code"
        return 1
    fi
}

# Основная логика
main() {
    CURRENT_STATE=$(check)
    
    # Читаем предыдущее состояние
    if [ -f "$STATE_FILE" ]; then
        PREVIOUS_STATE=$(cat "$STATE_FILE")
    else
        PREVIOUS_STATE="unknown"
    fi
    
    # Если процесс запущен
    if [ "$CURRENT_STATE" = "running" ]; then
        # Отправляем запрос к серверу мониторинга
        if ! sendReq; then
            # Ошибка уже залогирована в функции
            true
        fi
        
        # Проверяем, был ли процесс перезапущен
        if [ "$PREVIOUS_STATE" = "stopped" ] && [ "$CURRENT_STATE" = "running" ]; then
            log "INFO: Process '$PROCESS_NAME' was restarted"
        fi
    fi
    
    # Сохраняем текущее состояние
    echo "$CURRENT_STATE" > "$STATE_FILE"
}

# Запуск основной функции
main "$@"
