#!/bin/bash

# Скрипт мониторинга процесса
# Конфигурация
LOG_FILE="/var/log/monitoring.log"
URL="${URL:-https://test.com/monitoring/test/api}"
NAME="${NAME:-test}"
STATE_FILE="/var/run/process_monitor.state"
CURRENT_STATE=""

#проверки процесса
check() {
    if pgrep -x "$NAME" > /dev/null; then
        echo "running"
    else
        echo "stopped"
    fi
}


#логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}


# отправки запроса
sendReq() {
    local responseCode
    local curlOutput
    
    # Отправляем HTTPS запрос с таймаутом
    curlOutput=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 10 \
        --connect-timeout 5 \
        -H "User-Agent: ProcessMonitor/1.0" \
        "$URL" 2>&1)
    
    responseCode="$?"
    
    # Обрабатываем разные коды ошибок curl
    case "$responseCode" in
        0)
            if [ "$curlOutput" -eq 200 ] || [ "$curlOutput" -eq 201 ]; then
                log "INFO: Monitoring request sent successfully"
                return 0
            else
                log "ERROR: Monitoring server returned HTTP $curlOutput"
                return 1
            fi
            ;;
        6)
            log "ERROR: Could not resolve hostname: $URL"
            return 1
            ;;
        7)
            log "ERROR: Failed to connect to monitoring server"
            return 1
            ;;
        28)
            log "ERROR: Connection timeout to monitoring server"
            return 1
            ;;
        35)
            log "ERROR: SSL connection error to monitoring server"
            return 1
            ;;
        *)
            log "ERROR: Monitoring server unavailable (curl error: $responseCode)"
            return 1
            ;;
    esac
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
        sendReq
        
        # Проверяем, был ли процесс перезапущен
        if [ "$PREVIOUS_STATE" = "stopped" ] && [ "$CURRENT_STATE" = "running" ]; then
            log "INFO: Process '$NAME' was restarted"
        fi
    fi
    
    # Сохраняем текущее состояние
    echo "$CURRENT_STATE" > "$STATE_FILE"
}

# Запуск основной функции
main "$@"