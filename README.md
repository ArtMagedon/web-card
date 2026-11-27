# Web Card

Персональный сайт-резюме. Сайт статический: HTML, CSS и JavaScript находятся в `index.html`, фотография — в `photo6.jpg`. Для публикации используется отдельный Docker-контейнер с Nginx.

## Схема работы

```text
Браузер
  │ HTTPS
  ▼
Хостовый Nginx
  │ HTTP → 127.0.0.1:8080
  ▼
Docker-контейнер web-card
  │
  ▼
Nginx (в контейнере) → index.html, photo6.jpg
```

TLS завершается на хостовом Nginx. Контейнер обслуживает статические файлы по HTTP на внутреннем порту 8080 и публикует этот порт только на loopback-интерфейсе хоста. Сам контейнер не открывает порт сайта напрямую в интернет.

## Состав репозитория

- `index.html`, `photo6.jpg` — сайт и его изображение.
- `Dockerfile` — сборка образа сайта на базе официального Nginx Alpine.
- `nginx/default.conf` — конфигурация Nginx внутри контейнера.
- `compose.yaml` — запуск контейнера и привязка `127.0.0.1:8080`.
- `.dockerignore` — исключение файлов разработки из контекста сборки.
- `deploy/update.sh` — получение изменений из GitHub, проверка Compose и пересборка контейнера.

## Запуск на сервере

Требуются Docker Engine и Docker Compose plugin.

Первичная установка:

```bash
sudo git clone https://github.com/ArtMagedon/web-card.git /opt/web-card
cd /opt/web-card
sudo docker compose up -d --build
```

Проверка:

```bash
sudo docker compose ps
curl -I http://127.0.0.1:8080
```

Ожидаемый HTTP-статус — `200 OK`. Состояние контейнера можно посмотреть командой:

```bash
sudo docker compose logs -f
```

## Обновление сайта

После отправки изменений в GitHub на сервере достаточно выполнить одну команду:

```bash
cd /opt/web-card
sudo sh deploy/update.sh
```

Скрипт получает fast-forward обновление из ветки `main`, проверяет конфигурацию Compose, пересобирает образ и обновляет контейнер. Он не удаляет тома или данные других сервисов.

Образ собирается локально из текущего содержимого репозитория. Поэтому обновление сайта не зависит от ручного копирования файлов на сервер.

## Подключение к хостовому Nginx

Внешний Nginx должен проксировать домен `mikosmart.opik.net` на `http://127.0.0.1:8080`. TLS-сертификат и конфигурация внешнего Nginx управляются на сервере и намеренно не входят в контейнер.

Пример содержимого HTTPS-виртуального хоста:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name mikosmart.opik.net;

    ssl_certificate /etc/letsencrypt/live/mikosmart.opik.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mikosmart.opik.net/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

Перед добавлением такого блока необходимо выпустить сертификат для корневого домена и включить домен в HTTP-блок обработки ACME challenge. Это делается на хосте, отдельно от Docker-контейнера.
