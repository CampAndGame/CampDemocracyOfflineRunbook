@echo off
setlocal

cd /d "%~dp0"

if not exist .env (
    echo ERROR: .env не найден. Скопируйте .env.example в .env и заполните значения.
    exit /b 1
)

if exist images.tar (
    echo ^>^>^> Загрузка docker-образов из images.tar...
    docker load -i images.tar
)

if not exist data\media mkdir data\media
if not exist bundles mkdir bundles

echo ^>^>^> Запуск Democracy offline-стенда...
docker compose up -d
echo.
echo ^>^>^> Плеер:  http://localhost/
echo ^>^>^> Админка: http://localhost/admin/  (логин - пароль из ADMIN_LOCAL_PASSWORD)
echo ^>^>^> Логи:   docker compose logs -f democracy-api
