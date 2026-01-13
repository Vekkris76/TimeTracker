@echo off
REM =========================================================
REM TimeTracker v2.1.0 - Script de Despliegue a Produccion
REM =========================================================
REM
REM Servidor: 192.168.11.39
REM Usuario: miguel
REM Destino: /var/www/timetracker
REM
REM Requisitos:
REM - pscp.exe (PuTTY SCP) en el PATH o en la carpeta actual
REM - plink.exe (PuTTY SSH) en el PATH o en la carpeta actual
REM
REM Descarga PuTTY tools desde: https://www.putty.org/
REM =========================================================

setlocal enabledelayedexpansion

REM Configuracion
set SERVER=192.168.11.39
set USER=miguel
set PASSWORD=Mg137Pz248$
set REMOTE_PATH=/var/www/timetracker
set LOCAL_PATH=%~dp0..

:MENU
cls
echo.
echo =========================================================
echo   TimeTracker v2.1.0 - Gestion de Despliegue
echo =========================================================
echo.
echo Servidor: %SERVER%
echo Usuario: %USER%
echo Directorio remoto: %REMOTE_PATH%
echo Directorio local: %LOCAL_PATH%
echo.
echo =========================================================
echo   MENU DE OPCIONES
echo =========================================================
echo.
echo   1. Subir archivos al servidor (DEPLOY)
echo   2. Descargar archivos del servidor (BACKUP LOCAL)
echo   3. Ejecutar script de pre-deployment
echo   4. Ejecutar script de post-deployment
echo   5. Salir
echo.
echo =========================================================
echo.
set /p OPCION="Selecciona una opcion (1-5): "

if "%OPCION%"=="1" goto UPLOAD
if "%OPCION%"=="2" goto DOWNLOAD
if "%OPCION%"=="3" goto PRE_DEPLOY
if "%OPCION%"=="4" goto POST_DEPLOY
if "%OPCION%"=="5" goto END
echo.
echo Opcion no valida. Presiona cualquier tecla para continuar...
pause >nul
goto MENU

:UPLOAD
cls
echo.
echo =========================================================
echo   SUBIR ARCHIVOS AL SERVIDOR (DEPLOY v2.1.0)
echo =========================================================
echo.
echo Esta operacion subira la estructura organizada:
echo   app/public/
echo     - index.html, api.php
echo   app/config/
echo     - config.php, .env.example, composer.json
echo   app/src/Security/
echo     - env-loader.php, rate-limiter.php, etc.
echo   deployment/scripts/
echo     - pre-deploy.sh, deploy-production.sh, post-deploy-check.sh
echo   docs/
echo     - Toda la documentacion
echo.
echo IMPORTANTE:
echo   - Se creara un backup automatico en el servidor
echo   - .env NO se sube (debes crearlo manualmente)
echo   - Despues del deploy ejecuta migrate-pins.php UNA VEZ
echo.
set /p CONFIRMAR="Continuar? (S/N): "
if /i not "%CONFIRMAR%"=="S" goto MENU

REM Verificar herramientas
where pscp.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if not exist "pscp.exe" (
        echo.
        echo ERROR: No se encuentra pscp.exe
        echo.
        echo Descarga PuTTY tools desde: https://www.putty.org/
        echo O coloca pscp.exe y plink.exe en la carpeta actual
        echo.
        pause
        goto MENU
    )
)

where plink.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if not exist "plink.exe" (
        echo.
        echo ERROR: No se encuentra plink.exe
        echo.
        pause
        goto MENU
    )
)

echo.
echo Iniciando despliegue...
echo.

REM Crear backup en el servidor
echo [1/6] Creando backup en el servidor...
plink -batch -pw %PASSWORD% %USER%@%SERVER% "cd %REMOTE_PATH% && mkdir -p backups && tar -czf backups/backup_$(date +%%Y%%m%%d_%%H%%M%%S).tar.gz app/ docs/ 2>/dev/null || true"
if %ERRORLEVEL% EQU 0 (
    echo   [OK] Backup creado
) else (
    echo   [WARNING] No se pudo crear backup - continuando...
)

REM Subir estructura app/
echo.
echo [2/6] Subiendo aplicacion (app/)...
pscp -batch -r -pw %PASSWORD% "%LOCAL_PATH%\app" %USER%@%SERVER%:%REMOTE_PATH%/

REM Subir deployment/
echo.
echo [3/6] Subiendo scripts de deployment...
pscp -batch -r -pw %PASSWORD% "%LOCAL_PATH%\deployment" %USER%@%SERVER%:%REMOTE_PATH%/

REM Subir docs/
echo.
echo [4/6] Subiendo documentacion...
pscp -batch -r -pw %PASSWORD% "%LOCAL_PATH%\docs" %USER%@%SERVER%:%REMOTE_PATH%/

REM Subir docker/ y archivos raiz
echo.
echo [5/6] Subiendo configuracion Docker...
pscp -batch -r -pw %PASSWORD% "%LOCAL_PATH%\docker" %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% "%LOCAL_PATH%\docker-compose.yml" %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% "%LOCAL_PATH%\Dockerfile" %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% "%LOCAL_PATH%\.gitignore" %USER%@%SERVER%:%REMOTE_PATH%/

REM Establecer permisos
echo.
echo [6/6] Estableciendo permisos...
plink -batch -pw %PASSWORD% %USER%@%SERVER% "sudo chown -R www-data:www-data %REMOTE_PATH% && sudo chmod -R 755 %REMOTE_PATH% && sudo chmod 600 %REMOTE_PATH%/app/config/.env 2>/dev/null || true"

REM Hacer ejecutables los scripts
plink -batch -pw %PASSWORD% %USER%@%SERVER% "chmod +x %REMOTE_PATH%/deployment/scripts/*.sh"

echo.
echo =========================================================
echo   DESPLIEGUE COMPLETADO
echo =========================================================
echo.
echo Archivos subidos exitosamente.
echo.
echo PASOS SIGUIENTES (IMPORTANTE):
echo.
echo 1. Conectar por SSH al servidor:
echo    ssh %USER%@%SERVER%
echo.
echo 2. Ir al directorio:
echo    cd %REMOTE_PATH%
echo.
echo 3. Crear archivo .env (si no existe):
echo    cp app/config/.env.example app/config/.env
echo    nano app/config/.env
echo    (Configurar DB_*, APP_ENV=production, APP_DEBUG=false)
echo.
echo 4. Ejecutar migracion de PINs (SOLO UNA VEZ):
echo    php app/src/Database/migrate-pins.php
echo.
echo 5. Eliminar script de migracion:
echo    rm app/src/Database/migrate-pins.php
echo.
echo 6. Verificar deployment:
echo    sudo bash deployment/scripts/post-deploy-check.sh
echo.
echo 7. Reiniciar servicios:
echo    sudo systemctl restart php8.3-fpm nginx
echo.
echo Ver docs/UPGRADE_v2.1.0.md y docs/SECURITY.md para mas detalles.
echo.
pause
goto MENU

:DOWNLOAD
cls
echo.
echo =========================================================
echo   DESCARGAR ARCHIVOS DEL SERVIDOR (BACKUP LOCAL)
echo =========================================================
echo.
echo Esta operacion descargara todos los archivos del servidor
echo a una carpeta local con timestamp.
echo.
set /p CONFIRMAR="Continuar? (S/N): "
if /i not "%CONFIRMAR%"=="S" goto MENU

REM Verificar herramientas
where pscp.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if not exist "pscp.exe" (
        echo.
        echo ERROR: No se encuentra pscp.exe
        echo.
        pause
        goto MENU
    )
)

echo.
echo Creando carpeta de backup local...

REM Obtener fecha/hora para el nombre de carpeta
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set BACKUP_FOLDER=backup_%datetime:~0,8%_%datetime:~8,6%

mkdir "%LOCAL_PATH%\%BACKUP_FOLDER%"

echo.
echo Descargando archivos...
echo.

REM Descargar estructura completa
pscp -batch -r -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/app "%LOCAL_PATH%\%BACKUP_FOLDER%\"
pscp -batch -r -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/deployment "%LOCAL_PATH%\%BACKUP_FOLDER%\"
pscp -batch -r -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/docs "%LOCAL_PATH%\%BACKUP_FOLDER%\"
pscp -batch -r -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/docker "%LOCAL_PATH%\%BACKUP_FOLDER%\"

echo.
echo =========================================================
echo   BACKUP LOCAL COMPLETADO
echo =========================================================
echo.
echo Archivos descargados en:
echo %LOCAL_PATH%\%BACKUP_FOLDER%\
echo.
pause
goto MENU

:PRE_DEPLOY
cls
echo.
echo =========================================================
echo   EJECUTAR PRE-DEPLOYMENT CHECK
echo =========================================================
echo.
echo Este script verificara que el servidor esta listo para
echo el despliegue de v2.1.0
echo.
plink -batch -pw %PASSWORD% %USER%@%SERVER% "cd %REMOTE_PATH% && sudo bash deployment/scripts/pre-deploy.sh"
echo.
pause
goto MENU

:POST_DEPLOY
cls
echo.
echo =========================================================
echo   EJECUTAR POST-DEPLOYMENT CHECK
echo =========================================================
echo.
echo Este script verificara que el despliegue fue exitoso
echo.
plink -batch -pw %PASSWORD% %USER%@%SERVER% "cd %REMOTE_PATH% && sudo bash deployment/scripts/post-deploy-check.sh"
echo.
pause
goto MENU

:END
echo.
echo Saliendo...
endlocal
exit /b
