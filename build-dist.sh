#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Сборка оффлайн-дистрибутива стенда Democracy: тянет нужные docker-образы, складывает их в
# images.tar и пакует всё в один democracy-standalone-vX.zip для переноса на машину без интернета.
#
# Весь UI — образы из реестра (как онлайн), НИЧЕГО собирать на месте не нужно:
#   - democracy-player          — плеер (тот же образ, что онлайн)
#   - democracy-admin-standalone — облегчённая админка Democracy (свой образ, своя версия)
# Оператор на целевой машине: docker load < images.tar + docker compose up.

VERSION="${VERSION:-1.0.36}"
PLAYER_VERSION="${PLAYER_VERSION:-1.0.19}"
ADMIN_VERSION="${ADMIN_VERSION:-0.0.3}"
REGISTRY="2345234523452345234534"
IMAGES=(
  "${REGISTRY}/democracy-service:${VERSION}"
  "${REGISTRY}/democracy-player:${PLAYER_VERSION}"
  "${REGISTRY}/democracy-admin-standalone:${ADMIN_VERSION}"
  "postgres:15-alpine"
  "redis:7-alpine"
  "nginx:1.27-alpine"
)
# Стенд разворачивается на amd64 (мини-сервер N100 и т.п.). Тянем образы строго под amd64,
# иначе на arm-хосте (напр. Mac) мультиарх-базы (postgres/redis/nginx) скачаются как arm64.
PLATFORM="${PLATFORM:-linux/amd64}"
DIST="democracy-standalone-v${VERSION}"
OUT="${DIST}.zip"

echo ">>> [1/3] Pull образов под ${PLATFORM} (нужен интернет)..."
for img in "${IMAGES[@]}"; do
  echo "    pull $img"
  docker pull --platform "${PLATFORM}" "$img"
done

echo ">>> [2/3] docker save -> images.tar (${#IMAGES[@]} образов)..."
docker save -o images.tar "${IMAGES[@]}"

echo ">>> [3/3] Упаковка ${OUT}..."
rm -f "${OUT}"
# .env НЕ кладём (секреты); кладём .env.example
zip -r -q "${OUT}" \
  docker-compose.yml \
  nginx.conf \
  .env.example \
  start.sh start.bat \
  START.md \
  bundles \
  images.tar \
  -x "bundles/*.zip"
rm -f images.tar

echo ""
echo ">>> Готово: ${OUT} (api=${VERSION}, player=${PLAYER_VERSION}, admin=${ADMIN_VERSION})"
echo ">>> Перенеси архив на целевой комп, распакуй и следуй START.md."
