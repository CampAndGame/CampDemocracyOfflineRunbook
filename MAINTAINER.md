# MAINTAINER — сопровождение оффлайн-стенда Democracy

Документ для разработчика/мейнтейнера (не для оператора — тому нужен `START.md`).

## Статус: ГОТОВО ✅
Оффлайн-стенд собран, проверен вживую и раздаётся. Модель — **образная** (как онлайн): все компоненты это docker-образы из приватного реестра, UI не собирается на месте.

## Из чего состоит (6 контейнеров)
| Контейнер | Образ | Репозиторий-исходник |
|---|---|---|
| democracy-api | `2345…/democracy-service:1.0.37` | `CampAndGame/CampDemocracyService` (профиль `standalone`) |
| democracy-player | `2345…/democracy-player:1.0.19` | `DemocracyReact` (= `JS/Democracy`) — тот же образ, что онлайн |
| democracy-admin | `2345…/democracy-admin-standalone:0.0.3` | `CampAndGame/DemocracyAdminReact` |
| postgres | `postgres:15-alpine` | — |
| redis | `redis:7-alpine` | — |
| nginx | `nginx:1.27-alpine` (reverse-proxy) | конфиг в этом репо (`nginx.conf`) |

Реестр: приватный Docker Hub namespace `2345234523452345234534`.

## Модель раздачи
- **Репозиторий рунбука** — `CampAndGame/CampDemocracyOfflineRunbook` (**public**): конфиги + доки. Кода и секретов нет. Прямой ссылки на дистрибутив в нём НЕТ (специально).
- **Дистрибутив** — `democracy-standalone-vX.zip` (~471 MB, внутри `images.tar` со всеми 6 образами amd64 + конфиги + `START.md`). Лежит на **Google Drive**, ссылку оператору выдаём **отдельно** (не в репо, т.к. внутри приватные образы).
- Оператор: скачал zip → распаковал → вписал пароль в `.env` → `start.sh`. Реестр/токен ему не нужны (образы из `images.tar`).

## ⚠️ Процедура обновления при смене образов (ГЛАВНОЕ)
После правок в коде сервиса/фронта образы меняются — чтобы обновить стенд:

1. **Собери и запушь новый образ** (на amd64 — сервере, НЕ на arm-Маке):
   - **сервис:** бамп версии в `CampDemocracyService` (pom + `k8s/deployment.yaml`) → сборка+push на сервере → `…/democracy-service:X.Y.Z`;
   - **админка:** правки в `DemocracyAdminReact` → на сервере `git pull` в `/home/project/dev/DemocracyAdminReact` → `docker build`+push → бамп `democracy-admin-standalone:A.B.C`;
   - **плеер:** правки в `DemocracyReact` → пересборка `democracy-player:X` (как онлайн).
2. **Обнови версии в этом репо:**
   - `docker-compose.yml` — дефолты `VERSION` / `PLAYER_VERSION` / `ADMIN_VERSION`;
   - `build-dist.sh` — те же три переменные;
   - при желании — версию в `RUNBOOK.md`.
3. **Пересобери дистрибутив:** `./build-dist.sh` (тянет образы под `linux/amd64` даже с arm-Мака) → новый `democracy-standalone-vX.zip`.
4. **Перезалей zip на Google Drive** (замени файл по той же ссылке — тогда ссылка операторам не меняется).
5. Закоммить изменения этого репо.

> Версии образов независимы: сервис ведёт свою (1.0.x), плеер свою (1.0.x), админка свою (0.0.x). Бампай только то, что менял.

## Ключевые технические факты
- **nginx** = reverse-proxy: `/`→player:3001, `/admin/`→admin:3000 (срез `/admin`), `/api/democracy/`→api:8126 (срез префикса, роль gateway), `/api/democracy/ws/`→api `/ws/`, `/api/democracy/media/`→api (без среза). `/config.js` подменяется на `{apiBaseUrl:""}` (для плеера).
- **api mem_limit=1g** + `JAVA_OPTS` в compose: `MaxRAMPercentage=50` (heap ~512M) и `G1PeriodicGCInterval=300000` (возврат памяти ОС). Дефолт образа — 75% (онлайн); без mem_limit JVM взяла бы процент от RAM всего хоста. Работает с образом >= 1.0.37 (ENTRYPOINT читает `JAVA_OPTS`).
- **standalone-специфика бэка:** авто-сид пустой игры (0,0); импорт bundle из UI = REPLACE (переимпорт заменяет игру, чистит старое медиа); логин по локальному паролю (`/public/admin/auth/login`, HS256).
- **Сборка образов только amd64** (стенд/сервер amd64; Mac arm64 → `build-dist.sh` тянет с `--platform linux/amd64`).

## Ресурсы (для сайзинга сервера)
Старт: пик ~1 ядро на 40–75 с (JVM api), ~1.1 GiB. В работе: ~750 MiB, CPU ~0. Диск ~10–15 GB.
Минимум: 2 ядра / 2 GB / 15 GB. Комфортно: 2 ядра / 4 GB / 20 GB (Intel N100 хватает).
