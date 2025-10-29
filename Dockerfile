FROM nginx:alpine

# Копируем конфигурацию nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/ssl/server.crt /etc/nginx/ssl/server.crt
COPY nginx/ssl/server.key /etc/nginx/ssl/server.key

# Создаем директорию для логов
RUN mkdir -p /var/log/nginx

# Создаем простой JSON endpoint
RUN mkdir -p /usr/share/nginx/html/monitoring/test
COPY nginx/html/api.json /usr/share/nginx/html/monitoring/test/api

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
