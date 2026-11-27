#!/usr/bin/env sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "Запусти скрипт от root: sudo sh deploy/update.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

echo "==> Получение изменений из GitHub"
git pull --ff-only origin main

echo "==> Проверка конфигурации Docker Compose"
docker compose config -q

echo "==> Сборка и обновление контейнера"
docker compose up -d --build --remove-orphans

echo "==> Состояние контейнера"
docker compose ps
