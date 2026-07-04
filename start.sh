#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "ERROR: .env не найден. Скопируйте .env.example в .env и заполните значения." >&2
  exit 1
fi

# Оффлайн: если в дистрибутиве есть images.tar — грузим образы в локальный docker
if [ -f images.tar ]; then
  echo ">>> Загрузка docker-образов из images.tar..."
  docker load -i images.tar
fi

mkdir -p data/media bundles

echo ">>> Запуск Democracy offline-стенда..."
docker compose up -d
echo ""
echo ">>> Готово."
echo ">>> Плеер:  http://localhost/"
echo ">>> Админка: http://localhost/admin/  (логин — пароль из ADMIN_LOCAL_PASSWORD)"
echo ">>> Логи:   docker compose logs -f democracy-api"
