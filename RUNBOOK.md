# RUNBOOK — запуск стенда Democracy

Пошаговая инструкция: поднять игру **Democracy** на отдельном компьютере (мини-сервер / ноут ведущего).
Интернет нужен **только один раз** — скачать дистрибутив. Дальше стенд работает **сам, без сети**.

Версия: **1.0.36**.

---

## Шаг 0. Скачать дистрибутив
Всё в одном файле `democracy-standalone-vX.zip` (~471 MB — образы + конфиги внутри).

**Ссылку на скачивание запроси у организатора** (выдаётся отдельно, в репозитории её нет).

Скачай → распакуй в любую папку → работай в ней. Больше ничего качать не нужно.

---

## Из чего состоит (справочно)

6 контейнеров (`docker-compose.yml`) — **всё из образов, ничего собирать на месте не нужно**:

| Контейнер | Образ | Роль |
|-----------|-------|------|
| `democracy-postgres` | postgres:15-alpine | БД игры (раунды/вопросы/санкции/команды/звуки) |
| `democracy-redis` | redis:7-alpine | **runtime игры** (активная сессия, токены команд) — обязателен |
| `democracy-api` | `…/democracy-service:1.0.36` | API + WebSocket, профиль `standalone` |
| `democracy-player` | `…/democracy-player:1.0.19` | плеер игрока (тот же образ, что онлайн) |
| `democracy-admin` | `…/democracy-admin-standalone:0.0.3` | облегчённая Democracy-only админка (логин по паролю) |
| `democracy-ui` | nginx:1.27-alpine | reverse-proxy: `/`→player, `/admin/`→admin, `/api`+`/ws`→api |

UI — это **docker-образы из реестра** (как онлайн), а не собираемая на месте статика:
- плеер — `democracy-player` (репо `DemocracyReact`), same-origin задаётся через `/config.js` (отдаёт nginx);
- админка — `democracy-admin-standalone` (репо `DemocracyAdminReact`), свой baked `config.js` = same-origin.

Данные на диске (рядом с compose, переживают перезапуск):
- `./data/media` — медиафайлы игры (из импортированного bundle);
- БД и Redis — в docker-томах `pg-data` / `redis-data`;
- `./bundles` — сюда кладут `.zip` игры для авто-импорта.

---

## 1. Что нужно на машине
- Установлен **Docker** (Docker Desktop на Windows/macOS, или Docker Engine + Compose plugin на Linux). Больше ничего.
- Скачан и распакован дистрибутив из **Шага 0**.

## 2. Загрузить образы
Образы уже лежат в распакованной папке (`images.tar`) — грузятся из файла, **реестр/логин не нужны**. Это делает `start.sh` автоматически (Шаг 5). Вручную — если хочешь заранее:
```bash
docker load -i images.tar
```

## 3. Заполнить `.env`
```bash
cp .env.example .env
```
Заполнить:
```
ADMIN_LOCAL_PASSWORD=stand2026                      # пароль входа в админку
ADMIN_LOCAL_JWT_SECRET=<openssl rand -base64 32>    # любой секрет >= 32 символов
# DB_PASSWORD=...                                    # опционально
```

## 4. Положить bundle игры
Экспортированный в онлайне `bundle.zip` (админка → «Скачать bundle.zip») положить в `./bundles/`:
```
bundles/
└── my-game.zip
```
При первом старте `BundleAutoloadRunner` импортирует его автоматически (структуру → в Postgres, медиа → в `./data/media`), `on-conflict=SKIP`, идемпотентно по `bundle_id`.
> Можно и без файла заранее — bundle грузится позже через UI админки (импорт). **На standalone импорт из UI = REPLACE**: переимпорт заменяет текущую игру (слот один).

## 5. Запуск
```bash
./start.sh        # macOS / Linux  (грузит images.tar если есть, затем compose up)
start.bat         # Windows
```
или вручную: `docker compose up -d`.

## 6. Доступ
- **Плеер (команды):** `http://localhost/`
- **Админка (ведущий):** `http://localhost/admin/` → войти паролем из `ADMIN_LOCAL_PASSWORD`.
- Логи: `docker compose logs -f democracy-api` (там же видно `Autoload … IMPORTED`).

## 7. Проверить, что bundle импортировался
```bash
docker compose logs democracy-api | grep -i -E "autoload|bundle|imported"
```
В админке игра появится сразу (статус `DEVELOP`). Команды заходят по joinCode (он **регенерируется** при импорте — берите коды из админки, вкладка «Команды»).

---

## Жизненный цикл / обслуживание
```bash
docker compose ps                  # статус
docker compose logs -f democracy-api
docker compose down                # стоп (данные сохраняются)
docker compose down -v             # стоп + снести БД/Redis-тома (полный сброс)
```
Сбросить/заменить игру: переимпортировать другой bundle через админку (standalone = REPLACE), либо `DELETE /api/democracy/admin/democracies/{id}`.
Бэкап: `docker compose exec postgres pg_dump -U democracy democracy > backup.sql` + `tar czf media.tgz data/media`.

## Troubleshooting
- **`ADMIN_LOCAL_PASSWORD must be set`** — не заполнен `.env`.
- **Bundle не импортировался** — `docker compose logs democracy-api | grep -i bundle`; проверь формат zip и что он в `./bundles/`.
- **Команды не подключаются по joinCode** — игра должна быть в `WAITING_ACTIVE`/`ACTIVE` (в `DEVELOP` join закрыт); переведи статус в админке.
- **Картинки/звук не грузятся** — проверь том `./data/media` и что nginx проксирует `/api/democracy/media` (см. `nginx.conf`).
- **Порт 80 занят** — поменяй `ports: ["80:80"]` в compose на свободный (напр. `8080:80`).

## Связанные проекты
- `CampDemocracyService` — исходник API (профиль `standalone`).
- `DemocracyAdminReact` — облегчённая админка Democracy (логин по паролю) → образ `democracy-admin-standalone`.
- `DemocracyReact` (`JS/Democracy`) — игровое приложение команды → образ `democracy-player`.
- Контракт API — `docs/CampServices/API_CONTRACT/DEMOCRACY_SERVICE_API_CONTRACT.md`; архитектура — `…/INFRASTRUCTURE/DEMOCRACY_ARCHITECTURE.md` (§9 bundle, §12 standalone).
