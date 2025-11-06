#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
PID_FILE="/var/run/${NAME}.pid"
URL="https://test.com/monitoring/test/api"
NAME="test" 
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
            log "ERROR: Required dependency $dep is not installed"
            exit 1
        fi
    done
}

#отправки запроса
sendReq() {
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

#проверки процесса
checkProcess() {
    local currPID=""
    local prevPID=""
    
    checkDependens

    # поиск процесс
    if pgrep -f "$NAME" > /dev/null; then
        currPID=$(pgrep -f "$NAME" | head -1)
        log "INFO: Found system process with PID: $currPID"
    else
        # удаляем PID-файл если процесс не найден
        log "ERORR: Process $NAME is NOT running"
        if [ -f "$PID_FILE" ]; then
            rm -f "$PID_FILE"
        fi
    fi

    # читаем прошлый PID
    if [ -f "$PID_FILE" ]; then
        prevPID=$(cat "$PID_FILE" 2>/dev/null)
    fi

    #если процесс перезапущен
    if [ -n "$prevPID" ] && [ "$currPID" != "$prevPID" ]; then  
        log "INFO: Process $NAME was restarted. Old PID: $prevPID, New PID: $currPID"
    fi

    # Сохраняем текущий PID
    echo "$currPID" > "$PID_FILE"
    
    # Отправляем запрос на сервер
    if sendReq; then
        log "INFO: Process $NAME (PID: $currPID) monitoring check passed"
    else
        log "ERROR: Process $NAME monitoring check failed"
    fi
    
    echo "running"
}

# Основная логика
main() {
    checkProcess
}

main "$@"