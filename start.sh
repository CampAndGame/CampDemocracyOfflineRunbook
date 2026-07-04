#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# 1. .env — создаём из примера, если его нет
if [ ! -f .env ]; then
  cp .env.example .env
  echo ">>> Создан файл .env"
fi

# 2. Технический секрет — генерируем сами, если пустой
if ! grep -qE '^ADMIN_LOCAL_JWT_SECRET=.+' .env; then
  SECRET="$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)"
  sed -i.bak "s|^ADMIN_LOCAL_JWT_SECRET=.*|ADMIN_LOCAL_JWT_SECRET=${SECRET}|" .env && rm -f .env.bak
  echo ">>> Сгенерирован технический секрет"
fi

# 3. Пароль админки — обязателен, его вписывает оператор
if ! grep -qE '^ADMIN_LOCAL_PASSWORD=.+' .env; then
  echo ""
  echo "!!! НУЖНО ВПИСАТЬ ПАРОЛЬ АДМИНКИ."
  echo "!!! Открой файл .env текстовым редактором и в строке ADMIN_LOCAL_PASSWORD= впиши свой пароль,"
  echo "!!! например:  ADMIN_LOCAL_PASSWORD=stand2026"
  echo "!!! Сохрани файл и запусти ./start.sh снова."
  echo ""
  exit 1
fi

# 4. Образы — из файла, без интернета и логина в реестр
if [ -f images.tar ]; then
  echo ">>> Загрузка docker-образов из images.tar (первый раз — пара минут)..."
  docker load -i images.tar
fi

mkdir -p data/media bundles

echo ">>> Запуск стенда Democracy..."
docker compose up -d
echo ""
echo ">>> Готово."
echo ">>> Админка (ведущий): http://localhost/admin/"
echo ">>> Плеер (команды):   http://localhost/"
echo ">>> Логи:              docker compose logs -f democracy-api"
