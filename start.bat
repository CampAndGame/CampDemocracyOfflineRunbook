@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

rem 1. .env — создаём из примера, если нет
if not exist .env copy .env.example .env >nul

rem 2. Технический секрет — генерируем, если пустой
findstr /R "^ADMIN_LOCAL_JWT_SECRET=..*" .env >nul
if errorlevel 1 (
    for /f %%s in ('powershell -NoProfile -Command "[Convert]::ToBase64String((1..32 ^| ForEach-Object {Get-Random -Maximum 256}))"') do set "SECRET=%%s"
    powershell -NoProfile -Command "(Get-Content .env) -replace '^ADMIN_LOCAL_JWT_SECRET=.*','ADMIN_LOCAL_JWT_SECRET=!SECRET!' ^| Set-Content .env"
    echo ^>^>^> Сгенерирован технический секрет
)

rem 3. Пароль админки — обязателен
findstr /R "^ADMIN_LOCAL_PASSWORD=..*" .env >nul
if errorlevel 1 (
    echo.
    echo !!! НУЖНО ВПИСАТЬ ПАРОЛЬ АДМИНКИ.
    echo !!! Открой файл .env и в строке ADMIN_LOCAL_PASSWORD= впиши свой пароль,
    echo !!! например:  ADMIN_LOCAL_PASSWORD=stand2026
    echo !!! Сохрани и запусти start.bat снова.
    echo.
    exit /b 1
)

rem 4. Образы из файла
if exist images.tar (
    echo ^>^>^> Загрузка docker-образов из images.tar (первый раз - пара минут)...
    docker load -i images.tar
)

if not exist data\media mkdir data\media
if not exist bundles mkdir bundles

echo ^>^>^> Запуск стенда Democracy...
docker compose up -d
echo.
echo ^>^>^> Админка (ведущий): http://localhost/admin/
echo ^>^>^> Плеер (команды):   http://localhost/
echo ^>^>^> Логи:              docker compose logs -f democracy-api
