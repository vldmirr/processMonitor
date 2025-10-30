#!/bin/bash

mkdir -p nginx/ssl

# Генерируем SSL сертификаты
openssl req -x509 -newkey rsa:4096 -nodes \
    -out nginx/ssl/server.crt \
    -keyout nginx/ssl/server.key \
    -days 365 \
    -subj "/CN=test.com" \
    -addext "subjectAltName=DNS:test.com,DNS:localhost,IP:127.0.0.1"

# Создаем PEM файл (комбинация приватного ключа и сертификата)
cat nginx/ssl/server.key nginx/ssl/server.crt > nginx/ssl/server.pem

# Также создаем отдельные файлы в PEM формате
cp nginx/ssl/server.key nginx/ssl/server-key.pem
cp nginx/ssl/server.crt nginx/ssl/server-cert.pem

echo "SSL certificates generated in nginx/ssl/"
echo "You can now run: docker-compose up -d"