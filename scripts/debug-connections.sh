#!/bin/bash

echo "=== Debugging test.com connection ==="

# Проверяем DNS
echo "1. Checking DNS resolution:"
ping -c 1 test.com

echo -e "\n2. Checking /etc/hosts:"
grep "test.com" /etc/hosts || echo "test.com not found in /etc/hosts"

echo -e "\n3. Checking if port 443 is open:"
netstat -tuln | grep ":443 " || echo "Port 443 not listening"

echo -e "\n4. Testing HTTPS connection with different methods:"

echo "Method 1: curl with verbose"
curl -vk https://test.com/monitoring/test/api 2>&1 | head -20

echo -e "\nMethod 2: wget"
wget --no-check-certificate -O- https://test.com/monitoring/test/api 2>&1 | head -10

echo -e "\nMethod 3: openssl s_client"
echo | openssl s_client -connect test.com:443 -servername test.com 2>/dev/null | head -10

echo -e "\n=== Debug complete ==="
