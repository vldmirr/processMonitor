#!/bin/bash

set -e

echo "=== Process Monitor Uninstallation ==="

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Останавливаем и отключаем сервис
echo "Stopping and disabling services..."
systemctl stop process-monitor.timer 2>/dev/null || true
systemctl disable process-monitor.timer 2>/dev/null || true
systemctl stop process-monitor.service 2>/dev/null || true

# Удаляем файлы
echo "Removing files..."
rm -f /usr/local/bin/process_monitor.sh
rm -f /etc/systemd/system/process-monitor.service
rm -f /etc/systemd/system/process-monitor.timer

# Перезагружаем systemd
echo "Reloading systemd..."
systemctl daemon-reload

# Удаляем файлы состояния (опционально)
read -p "Remove state and log files? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f /var/run/process_monitor.state
    rm -f /var/log/monitoring.log
    echo "State and log files removed"
else
    echo "State and log files preserved"
fi

echo ""
echo "=== Uninstallation completed! ==="