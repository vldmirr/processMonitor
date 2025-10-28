#!/bin/bash

set -e

echo "=== Process Monitor Installation ==="

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")/src"

echo "Source directory: $SRC_DIR"

# Создаем директории
# echo "Creating directories..."
# mkdir -p /usr/local/bin

# Копируем скрипт
echo "Installing process monitor script..."
cp "$SRC_DIR/process_monitor.sh" /usr/local/bin/
chmod +x /usr/local/bin/process_monitor.sh

# Копируем systemd файлы
echo "Installing systemd services..."
cp "$SRC_DIR/process-monitor.service" /etc/systemd/system/
cp "$SRC_DIR/process-monitor.timer" /etc/systemd/system/

# Создаем файл лога
echo "Creating log file..."
touch /var/log/monitoring.log
chmod 644 /var/log/monitoring.log

# Перезагружаем systemd
echo "Reloading systemd..."
systemctl daemon-reload

# Включаем и запускаем таймер
echo "Enabling and starting timer..."
systemctl enable process-monitor.timer
systemctl start process-monitor.timer

echo ""
echo "=== Installation completed successfully! ==="
echo ""
echo "Usage:"
echo "  Check status: systemctl status process-monitor.timer"
echo "  View logs: tail -f /var/log/monitoring.log"
echo "  Run: systemctl start process-monitor.service"
echo ""
echo "Config:"
echo "  Edit /etc/systemd/system/process-monitor.service to change:"
echo "  - PROCESS_NAME environment variable"
echo "  - MONITORING_URL environment variable"
echo ""