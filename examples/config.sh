#!/bin/bash
# Пример настройки кастомной конфигурации

# Останавливаем сервис
systemctl stop process-monitor.timer

# Создаем кастомный service файл
cat > /etc/systemd/system/process-monitor.service << 'EOF'
[Unit]
Description=Process Monitor Service
After=network.target

[Service]
Type=oneshot
User=root
Environment="PROCESS_NAME=nginx"
Environment="MONITORING_URL=https://api.example.com/health"
ExecStart=/usr/local/bin/process_monitor.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

# Перезагружаем и запускаем
systemctl daemon-reload
systemctl start process-monitor.timer

echo "Custom configuration applied:"
echo " - Monitoring process: nginx"
echo " - Monitoring URL: https://api.example.com/health"