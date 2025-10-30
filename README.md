# processMonitor

## Структура проекта

```text
process-monitor/
├── examples/
│   ├── test                 # Пример тестового процесса
├── nginx/
│   ├── ssl                  # содержится *.crt,*.key,*.pem файлы, (генерируются при помощи generate_cert.sh)
│   ├── html
|   |   └── api.json         # файл который формирует ответ при запросе через https
│   └── nginx.conf           # конфигурационный файл веб-сервера
├── scripts/ # Вспомогательные скрипты
|   ├── setup-fix.sh         # для регенирации и внемения test.com напрямую в /etc/hosts 
│   ├── generate_cert.sh     # по генерации ssl файлов
│   ├── debug-connections.sh # для проверки dns
│   ├── install.sh           # установки
│   └── uninstall.sh         # удаления
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

### Cгенирировать ssl файлы
```bash
sudo chmod +x ./scripts/generate_cert.sh
sudo ./scripts/generate_cert.sh
```

## Использование 

### Запуск сервиса:

```bash
sudo systemctl start process-monitor.service
```

### Взаимодействие с тестовым процессом:

```bash
cd processMonitor
sudo docker-compose up -d
```
После чего запустятся следующие контейнеры:

- `test`-сам тестовый процесс **работа** и **PID** которых мониторятся в логах каждую минуту.
- `dns-server`-сервер на котором запускается доменное имя **https://test.com/monitoring/test/api**.
- `server`-контейнер на котором поднимаю сайт **test.com**

Проверьте работу сервера:

```bash
curl -k https://test.com/monitoring/test/api
```

### Проверка статуса:

```bash
sudo systemctl status process-monitor.timer

sudo journalctl -u process-monitor.service -f

systemctl list-timers
```

## Логирование

Просмотр лого осуществлятся при помощи данной комманды:

```bash
tail -f /var/log/monitoring.log
```

Скрипт записывает следующие события в /var/log/monitoring.log:

- **response:** Данные с запроса

- **HTTP code:** Код ответа или код ошибки возникшая в процессе запроса

- **INFO:** Информация о запуске/остановки процесса

- **ERROR:** Ошибка о не доступности сервера

Пример логов:

```text
2025-10-30 13:24:11 - INFO: Process test (PID: 1389) is running and monitoring check passed
2025-10-30 13:25:12 - INFO: Process test is NOT running
2025-10-30 13:26:13 - INFO: Process test is runnig
2025-10-30 13:26:13 - INFO: Process test is NOT running
2025-10-30 13:26:13 - INFO: Process test was restarted. Old PID: 1389, New PID: 2339
2025-10-30 13:26:13 - {"status": "ok", "message": "Monitoring endpoint working", "timestamp": "30/Oct/2025:10:26:13 +0000"}
2025-10-30 13:26:13 - HTTP code: 200
```

## Удаление 

```bash
sudo docker-compose down
sudo chmod +x scripts/uninstall.sh
sudo ./scripts/uninstall.sh
```