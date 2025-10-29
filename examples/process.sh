#!/bin/bash

PROCESS_NAME="test"

startProcess() {
    echo "Starting test process..."
    while true; do
        sleep 10
    done &
    echo "Test process started with PID: $!"
}

stopProcess() {
    echo "Stopping test process..."
    pkill -f "sleep 10" 2>/dev/null && echo "Test process stopped" || echo "No test process running"
}

case "$1" in
    start)
        startProcess
        ;;
    stop)
        stopProcess
        ;;
    restart)
        stopProcess
        sleep 2
        startProcess
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac