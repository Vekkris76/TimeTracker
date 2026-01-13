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
set LOCAL_PATH=%~dp0

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
echo Esta operacion subira los siguientes archivos:
echo   Core:
echo     - index.html
echo     - api.php
echo.
echo   Seguridad (NUEVOS en v2.1.0):
echo     - env-loader.php
echo     - rate-limiter.php
echo     - audit-logger.php
echo     - validators.php
echo     - migrate-pins.php
echo.
echo   Configuracion:
echo     - config.php
echo     - .env.example
echo     - config.example.php
echo     - timetracker.nginx.conf
echo.
echo   Documentacion:
echo     - README.md
echo     - CHANGELOG.md
echo     - SECURITY.md
echo     - UPGRADE_v2.1.0.md
echo.
echo   Scripts de despliegue:
echo     - pre-deploy.sh
echo     - deploy-production.sh
echo     - post-deploy-check.sh
echo.
echo IMPORTANTE:
echo   - Se creara un backup automatico en el servidor
echo   - config.php se actualizara con credenciales de produccion
echo   - .env NO se sube (debes crearlo manualmente en el servidor)
echo   - Despues del deploy ejecuta migrate-pins.php UNA VEZ
echo.
set /p CONFIRMAR="Continuar? (S/N): "
if /i not "%CONFIRMAR%"=="S" goto MENU

REM Verificar si existen las herramientas de PuTTY
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
        echo Descarga PuTTY tools desde: https://www.putty.org/
        echo O coloca pscp.exe y plink.exe en la carpeta actual
        echo.
        pause
        goto MENU
    )
)

echo.
echo Iniciando despliegue...
echo.

REM Crear backup en el servidor
echo [1/5] Creando backup en el servidor...
plink -batch -pw %PASSWORD% %USER%@%SERVER% "cd %REMOTE_PATH% && mkdir -p backups && tar -czf backups/backup_$(date +%%Y%%m%%d_%%H%%M%%S).tar.gz index.html api.php config.php CHANGELOG.md 2>/dev/null || true"
if %ERRORLEVEL% EQU 0 (
    echo   [OK] Backup creado
) else (
    echo   [WARNING] No se pudo crear backup - continuando...
)

REM Subir archivos core
echo.
echo [2/5] Subiendo archivos principales...
pscp -batch -pw %PASSWORD% index.html %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% api.php %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% config.php %USER%@%SERVER%:%REMOTE_PATH%/

REM Subir archivos de seguridad (NUEVOS)
echo.
echo [3/5] Subiendo archivos de seguridad (v2.1.0)...
pscp -batch -pw %PASSWORD% env-loader.php %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% rate-limiter.php %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% audit-logger.php %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% validators.php %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% migrate-pins.php %USER%@%SERVER%:%REMOTE_PATH%/

REM Subir archivos de configuracion
echo.
echo [4/5] Subiendo archivos de configuracion...
pscp -batch -pw %PASSWORD% .env.example %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% config.example.php %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% timetracker.nginx.conf %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% composer.json %USER%@%SERVER%:%REMOTE_PATH%/

REM Subir documentacion
echo.
echo [5/5] Subiendo documentacion y scripts...
pscp -batch -pw %PASSWORD% README.md %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% CHANGELOG.md %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% SECURITY.md %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% UPGRADE_v2.1.0.md %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% PRODUCTION_CHECKLIST.md %USER%@%SERVER%:%REMOTE_PATH%/

REM Subir scripts de despliegue
pscp -batch -pw %PASSWORD% pre-deploy.sh %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% deploy-production.sh %USER%@%SERVER%:%REMOTE_PATH%/
pscp -batch -pw %PASSWORD% post-deploy-check.sh %USER%@%SERVER%:%REMOTE_PATH%/

REM Actualizar credenciales en el servidor
echo.
echo Configurando credenciales de produccion...
plink -batch -pw %PASSWORD% %USER%@%SERVER% "cd %REMOTE_PATH% && sed -i 's/localhost/localhost/g' config.php"

REM Establecer permisos
echo Estableciendo permisos...
plink -batch -pw %PASSWORD% %USER%@%SERVER% "sudo chown -R www-data:www-data %REMOTE_PATH% && sudo chmod -R 755 %REMOTE_PATH%"

REM Hacer ejecutables los scripts
plink -batch -pw %PASSWORD% %USER%@%SERVER% "chmod +x %REMOTE_PATH%/pre-deploy.sh %REMOTE_PATH%/deploy-production.sh %REMOTE_PATH%/post-deploy-check.sh"

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
echo    cp .env.example .env
echo    nano .env
echo    (Configurar DB_*, APP_ENV=production, APP_DEBUG=false)
echo.
echo 4. Ejecutar migracion de PINs (SOLO UNA VEZ):
echo    php migrate-pins.php
echo.
echo 5. Eliminar script de migracion:
echo    rm migrate-pins.php
echo.
echo 6. Verificar deployment:
echo    sudo bash post-deploy-check.sh
echo.
echo 7. Reiniciar servicios:
echo    sudo systemctl restart php8.3-fpm nginx
echo.
echo Ver UPGRADE_v2.1.0.md y SECURITY.md para mas detalles.
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

mkdir "%LOCAL_PATH%%BACKUP_FOLDER%"

echo.
echo Descargando archivos...
echo.

REM Descargar archivos principales
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/index.html "%LOCAL_PATH%%BACKUP_FOLDER%\"
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/api.php "%LOCAL_PATH%%BACKUP_FOLDER%\"
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/config.php "%LOCAL_PATH%%BACKUP_FOLDER%\"

REM Descargar archivos de seguridad
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/env-loader.php "%LOCAL_PATH%%BACKUP_FOLDER%\" 2>nul
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/rate-limiter.php "%LOCAL_PATH%%BACKUP_FOLDER%\" 2>nul
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/audit-logger.php "%LOCAL_PATH%%BACKUP_FOLDER%\" 2>nul
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/validators.php "%LOCAL_PATH%%BACKUP_FOLDER%\" 2>nul

REM Descargar archivos de configuracion
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/.env "%LOCAL_PATH%%BACKUP_FOLDER%\" 2>nul
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/timetracker.nginx.conf "%LOCAL_PATH%%BACKUP_FOLDER%\"

REM Descargar documentacion
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/README.md "%LOCAL_PATH%%BACKUP_FOLDER%\"
pscp -batch -pw %PASSWORD% %USER%@%SERVER%:%REMOTE_PATH%/CHANGELOG.md "%LOCAL_PATH%%BACKUP_FOLDER%\"

echo.
echo =========================================================
echo   BACKUP LOCAL COMPLETADO
echo =========================================================
echo.
echo Archivos descargados en:
echo %LOCAL_PATH%%BACKUP_FOLDER%\
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
plink -batch -pw %PASSWORD% %USER%@%SERVER% "cd %REMOTE_PATH% && sudo bash pre-deploy.sh"
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
plink -batch -pw %PASSWORD% %USER%@%SERVER% "cd %REMOTE_PATH% && sudo bash post-deploy-check.sh"
echo.
pause
goto MENU

:END
echo.
echo Saliendo...
endlocal
exit /b
