# processMonitor

## Структура проекта

```text
process-monitor/
├── examples/
│   ├── test         # Пример тестового процесса
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
#запуск
sudo cp examples/test /usr/local/bin/test
sudo chmod +x /usr/local/bin/test
sudo /usr/local/bin/test &

# Убьем процесс test
sudo pkill -f "/usr/local/bin/test"

# Подождем минуту или запустим монитор вручную
sudo /usr/local/bin/process_monitor.sh

# Запустим процесс снова
sudo /usr/local/bin/test &

# Снова запустим монитор - должен залогировать перезапуск
sudo /usr/local/bin/process_monitor.sh
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

- **response:** Данные с запроса

- **HTTP code:** Код ответа или код ошибки возникшая в процессе запроса

- **INFO:** Информация о запуске/остановки процесса

- **ERROR:** Ошибка о не доступности сервера

Пример логов:

```text
2025-10-29 13:26:12 - {
  "uuid": "085c7e80-6eb7-445a-aff1-ef40e98b8de5"
}
2025-10-29 13:26:12 - HTTP code: 200

```

## Удаление 

```bash
sudo scripts/uninstall.sh
```