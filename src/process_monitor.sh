#!/bin/bash

#"https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"
URL="https://httpbin.dev/uuid"
NAME="test"
PID="/var/run/${NAME}.pid" 
STATE_FILE="/var/run/process_monitor.state"
CURRENT_STATE=""

#логирование
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

#проверки процесса
check() {
    #прошлый и текущий пид
    local currPID
    local prevPID

    currPID=$(pgrep -f "$NAME" | head -1)

    #информируем о запуске или остановке контейнера
    if pgrep -x "$NAME" > /dev/null; then
        prevPID=$(cat "$PID" 2>/dev/null) 
        log "INFO: Process $NAME is running"
        echo "running"
    else
        prevPID=""
        log "INFO: Process $NAME is NOT running"
        echo "stopped"
    fi

    #Если процесс запущен
    if [ -n "$currPID" ]; then 
        # Проверка на перезапуск
        if [ -n "$prevPID" ] && [ "$currPID" != "$prevPID" ]; then  # Fixed: added spaces
            log "INFO: Process $NAME was restarted. Old PID: $prevPID, New PID: $currPID"
        fi

        echo "$currPID" > "$PID"

        #Отправляем запрос на сервер
        if sendReq; then
            log "INFO: Process $NAME (PID: $currPID) is running and monitoring check passed"
        fi
    # Удаление процесса если тот не запущен
    # else 
    #     if [ -f "$PID" ]; then  # Fixed: added spaces
    #         rm -f "$PID"
    #     fi
    fi
}

#отправки запроса
sendReq() {
    local response_code
    local response

    #получаем данные с запроса
    response=$(curl -sS "$URL")
    # Отправляем HTTPS запрос и получаем код ответа
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    
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
    CURRENT_STATE=$(check)
    
    # Читаем предыдущее состояние
    if [ -f "$STATE_FILE" ]; then
        PREVIOUS_STATE=$(cat "$STATE_FILE")
    else
        PREVIOUS_STATE="unknown"
    fi
    
    # Если процесс запущен отправляем запрос 
    if [ "$CURRENT_STATE" = "running" ]; then
       
        if ! sendReq; then
            true
        fi
        
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
