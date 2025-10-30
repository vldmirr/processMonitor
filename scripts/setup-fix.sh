#!/bin/bash

echo "Fixing test.com configuration..."

# Останавливаем все контейнеры
docker-compose down

# Добавляем в /etc/hosts если нет
if ! grep -q "test.com" /etc/hosts; then
    echo "Adding test.com to /etc/hosts..."
    echo "127.0.0.1 test.com" | sudo tee -a /etc/hosts
fi

# Пересоздаем SSL сертификаты
echo "Regenerating SSL certificates..."
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout nginx/ssl/server.key \
    -out nginx/ssl/server.crt \
    -days 365 \
    -subj "/CN=test.com" \
    -addext "subjectAltName=DNS:test.com,DNS:localhost,IP:127.0.0.1"

# Запускаем сервисы
echo "Starting services..."
docker-compose up -d

# Ждем запуска
sleep 3

# Проверяем
echo "Testing connection..."
curl -k https://test.com/monitoring/test/api

echo "Setup complete!"
