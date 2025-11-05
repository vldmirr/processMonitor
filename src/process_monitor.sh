#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
URL="https://test.com/monitoring/test/api"
NAME="test"
PID_FILE="/var/run/${NAME}.pid" 
STATE_FILE="/var/run/process_monitor.state"
CURRENT_STATE=""
CURL_OPTS="-k --cacert nginx/ssl/server.pem --connect-timeout 10 --max-time 30"

#логирование
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

#проверки зависимостей
checkDependens() {
    local deps=("curl" "pgrep")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_message "ERROR: Required dependency $dep is not installed"
            exit 1
        fi
    done
}

#проверки процесса
checkProcess() {
    local currPID=""
    local prevPID=""
    local process_found=false
    
    checkDependens

    # поиск процесс
    currPID=$(pgrep -f "$NAME" | head -1)
    
    if [ -n "$currPID" ]; then
        process_found=true
        log "INFO: Process $NAME is running (PID: $currPID)"
    else
        log "INFO: Process $NAME is NOT running"
        # удаляем PID-файл если процесс не найден
        if [ -f "$PID_FILE" ]; then
            rm -f "$PID_FILE"
        fi
        echo "stopped"
        return
    fi

    # читаем прошлый PID
    if [ -f "$PID_FILE" ]; then
        prevPID=$(cat "$PID_FILE" 2>/dev/null)
    fi

    #если процесс перезапущен
    if [ -n "$prevPID" ] && [ "$currPID" != "$prevPID" ]; then  
        log "INFO: Process $NAME was restarted. Old PID: $prevPID, New PID: $currPID"
    elif [ -z "$prevPID" ]; then
        log "INFO: Process $NAME started. PID: $currPID"
    fi

    # Сохраняем текущий PID
    echo "$currPID" > "$PID_FILE"
    
    # Отправляем запрос на сервер
    if sendReq; then
        log "INFO: Process $NAME (PID: $currPID) monitoring check passed"
    else
        log "WARNING: Process $NAME (PID: $currPID) monitoring check failed"
    fi
    
    echo "running"
}

#отправки запроса
sendReq() {
    local responseCode
    local response

    #код/ответ
    response=$(curl -sS -w "\n%{http_code}" $CURL_OPTS "$URL" 2>/dev/null)
    response_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$response_code" -eq 200 ] || [ "$response_code" -eq 201 ]; then
        log "$response"
        log "HTTP code: $response_code"
        return 0 
    else
        log "$response"
        log "ERROR: Monitoring server unavailable. HTTP code: $response_code"
        return 1
    fi
}

# Основная логика
main() {
    local previous_state=""
    
    CURRENT_STATE=$(checkProcess)
    
    # Читаем предыдущее состояние
    if [ -f "$STATE_FILE" ]; then
        previous_state=$(cat "$STATE_FILE")
    else
        previous_state="unknown"
    fi
    
    # был ли процесс перезапущен
    if [ "$previous_state" = "stopped" ] && [ "$CURRENT_STATE" = "running" ]; then
        log "INFO: Process '$NAME' was restarted (state change: stopped → running)"
    elif [ "$previous_state" = "running" ] && [ "$CURRENT_STATE" = "stopped" ]; then
        log "INFO: Process '$NAME' was stopped (state change: running → stopped)"
    fi
    
    # сохраняем текущее состояние
    echo "$CURRENT_STATE" > "$STATE_FILE"
}

main "$@"