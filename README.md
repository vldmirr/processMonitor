# processMonitor

## Структура проекта

```text
process-monitor/
├── examples/
│   ├── process.sh           # Пример тестового процесса
│   └── config.sh            # Пример конфигурации
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
cd process-monitor
sudo scripts/install.sh
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

### Запуск тестового процесса

```bash
sudo examples/test_process.sh start
```

### Проверка статуса:

```bash
# Статус таймера
systemctl status process-monitor.timer

# История запусков
journalctl -u process-monitor.service

# Просмотр логов
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