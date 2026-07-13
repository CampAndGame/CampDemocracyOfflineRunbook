# CampDemocracyOfflineRunbook

Источник + инструкции для запуска игры **Democracy** на отдельном компьютере **оффлайн** (стенд ведущего), из docker-образов. Это **не сервис** — только сборка/раздача стенда и runbook.

## Что внутри
- **`RUNBOOK.md`** — пошаговый запуск на чистой машине (главный документ).
- **`docker-compose.yml`** — 6 контейнеров (postgres + redis + democracy-api[standalone] + democracy-player + democracy-admin + nginx-proxy), версия сервиса `${VERSION:-1.0.36}`.
- **`nginx.conf`** — reverse-proxy: `/`→player, `/admin/`→admin, `/api`+`/ws`→api.
- **`.env.example`** — `ADMIN_LOCAL_PASSWORD`, `ADMIN_LOCAL_JWT_SECRET`.
- **`build-dist.sh`** — собирает оффлайн-архив: `docker save` образов → `images.tar` + упаковка `democracy-standalone-vX.zip`.
- **`start.sh` / `start.bat`** — грузят `images.tar` (если есть) и поднимают стенд.
- **`bundles/`** — сюда кладут `.zip` игры (autoload при старте).

## UI — это образы (как онлайн), собирать на месте не нужно
Весь UI поставляется docker-образами из реестра (лежат в `images.tar`):
- **плеер** — `democracy-player` (репо `DemocracyReact` / `JS/Democracy`), тот же образ, что онлайн; same-origin задаётся через `/config.js` (отдаёт nginx стенда);
- **админка** — `democracy-admin-standalone` (репо `DemocracyAdminReact`) — облегчённая Democracy-only админка, логин по локальному паролю.

## Быстрый старт
1. `./build-dist.sh` (на машине с интернетом + доступом к реестру) → тянет все образы → `democracy-standalone-v1.0.36.zip`.
2. Перенести архив на целевой комп, распаковать.
3. Следовать `RUNBOOK.md` (`.env` → bundle в `./bundles/` → `./start.sh`).

## Версии образов (env для build-dist / compose)
- `VERSION` — democracy-service (по умолчанию `1.0.36`);
- `PLAYER_VERSION` — democracy-player (по умолчанию `1.0.17`);
- `ADMIN_VERSION` — democracy-admin-standalone (по умолчанию `0.0.1`).
