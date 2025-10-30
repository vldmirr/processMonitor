#!/bin/bash

#"https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"
URL="https://localhost:8443/monitoring/test/api"
NAME="test"
PID="/var/run/${NAME}.pid" 
STATE_FILE="/var/run/process_monitor.state"
CURRENT_STATE=""
CURL_OPTS="-k --cacert nginx/ssl/server.pem --connect-timeout 10 --max-time 30"

#логирование
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

#проверки зависимостей
checkDependen() {
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
    #прошлый и текущий пид
    local currPID
    local prevPID

    currPID=$(pgrep -f "$NAME" | head -1)

    #Ищем процесс (включая Docker контейнеры)
    if pgrep -f "$NAME" > /dev/null; then
        currPID=$(pgrep -f "$NAME" | head -1) 
    else
        currPID=""
    fi

    #Читаем предыдущий PID из файла
    if [ -f "$PID" ]; then
        prevPID=$(cat "$PID" 2>/dev/null)
        echo "running"
    else
        prevPID=""
        log "INFO: Process $NAME is NOT running"
        echo "stopped"
    fi
    

    #Если процесс запущен
    if [ -n "$currPID" ]; then 
        # Проверка на перезапуск
        if [ -n "$prevPID" ] && [ "$currPID" != "$prevPID" ]; then  
            log "INFO: Process $NAME was restarted. Old PID: $prevPID, New PID: $currPID"
        elif [ -z "$prevPID" ]; then
            log "INFO: Process $NAME started. PID: $current_pid"

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
    local responseCode
    local response

    #получаем данные с запроса
    response=$(curl -sS $CURL_OPTS  "$URL")
    # Отправляем HTTPS запрос и получаем код ответа
    response_code=$(curl -s -o /dev/null -w "%{http_code}" $CURL_OPTS "$URL" 2>/dev/null)
    
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

    CURRENT_STATE=$(checkProcess)
    
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
    
    checkDependen

}

# Запуск основной функции
main "$@"
