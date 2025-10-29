# processMonitor

## Структура проекта

```text
process-monitor/
├── examples/
│   ├── process.sh           # Пример тестового процесса
├── scripts/
│   ├── install.sh           # Скрипт установки
│   └── uninstall.sh         # Скрипт удаления
├── src/
│   ├── process_monitor.sh          # Основной скрипт мониторинга
│   ├── process-monitor.service     # Systemd service файл
│   └── process-monitor.timer       # Systemd timer файл
└── README.md
```

## Установка

### Быстрая установка:

```bash
git clone https://github.com/vldmirr/processMonitor
cd processMonitor
sudo chmod +x scripts/install.sh
sudo ./scripts/install.sh
```

### Ручная установка:

```bash
sudo cp src/process_monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/process_monitor.sh

sudo cp src/process-monitor.service /etc/systemd/system/
sudo cp src/process-monitor.timer /etc/systemd/system/

sudo touch /var/log/monitoring.log
sudo chmod 644 /var/log/monitoring.log

sudo systemctl daemon-reload
sudo systemctl enable process-monitor.timer
sudo systemctl start process-monitor.timer
```

## Использование 

### Запуск сервиса:

```bash
sudo systemctl start process-monitor.service
```

### Взаимодействие с тестовым процессом

```bash
sudo examples/process.sh start
sudo examples/process.sh restart
sudo examples/process.sh stop
```

### Проверка статуса:

```bash
sudo systemctl status process-monitor.timer

sudo journalctl -u process-monitor.service -f

systemctl list-timers

tail -f /var/log/monitoring.log
```

## Логирование

Скрипт записывает следующие события в /var/log/monitoring.log:

- **INFO:** Успешная отправка запроса, перезапуск процесса

- **ERROR:** Проблемы с сервером мониторинга

Пример логов:

```text
2025-10-26 22:40:00 - INFO: Monitoring request sent successfully
2025-10-26 22:41:00 - INFO: Process 'nginx' was restarted
2025-10-26 22:42:00 - ERROR: Monitoring server unavailable (curl error: 7)
```

## Удаление 

```bash
sudo scripts/uninstall.sh
```