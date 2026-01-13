@echo off
REM =========================================================
REM TimeTracker v2.0.4 - Script de Despliegue a Produccion
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
echo   TimeTracker v2.0.4 - Gestion de Despliegue
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
echo   3. Salir
echo.
echo =========================================================
echo.
set /p OPCION="Selecciona una opcion (1-3): "

if "%OPCION%"=="1" goto UPLOAD
if "%OPCION%"=="2" goto DOWNLOAD
if "%OPCION%"=="3" goto END
echo.
echo Opcion no valida. Presiona cualquier tecla para continuar...
pause >nul
goto MENU

:UPLOAD
cls
echo.
echo =========================================================
echo   SUBIR ARCHIVOS AL SERVIDOR (DEPLOY)
echo =========================================================
echo.
echo Esta operacion subira los siguientes archivos:
echo   - index.html
echo   - api.php
echo   - config.php (con credenciales de produccion)
echo   - timetracker.nginx.conf
echo   - CHANGELOG.md
echo   - README.md
echo.
echo IMPORTANTE: Se creara un backup automatico en el servidor
echo             antes de sobreescribir los archivos.
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
echo [1/7] Creando backup en servidor...
echo.
plink.exe -batch -pw "%PASSWORD%" %USER%@%SERVER% "cd %REMOTE_PATH% && mkdir -p backups && tar -czf backups/backup_$(date +%%Y%%m%%d_%%H%%M%%S).tar.gz index.html api.php config.php timetracker.nginx.conf CHANGELOG.md README.md 2>/dev/null; echo 'Backup creado'"
if %ERRORLEVEL% NEQ 0 (
    echo ADVERTENCIA: No se pudo crear backup ^(puede ser el primer despliegue^)
)

echo.
echo [2/7] Subiendo index.html...
pscp.exe -batch -pw "%PASSWORD%" "%LOCAL_PATH%index.html" %USER%@%SERVER%:%REMOTE_PATH%/index.html
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al subir index.html
    pause
    goto MENU
)

echo.
echo [3/7] Subiendo api.php...
pscp.exe -batch -pw "%PASSWORD%" "%LOCAL_PATH%api.php" %USER%@%SERVER%:%REMOTE_PATH%/api.php
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al subir api.php
    pause
    goto MENU
)

echo.
echo [4/7] Subiendo config.php con credenciales de produccion...
REM Crear config.php temporal con credenciales de produccion
(
echo ^<?php
echo $host = 'localhost';
echo $db = 'timetracker';
echo $user = 'timetracker_user';
echo $pass = 'Tm135Tk579$';
echo $charset = 'utf8mb4';
echo.
echo $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
echo $options = [
echo     PDO::ATTR_ERRMODE            =^> PDO::ERRMODE_EXCEPTION,
echo     PDO::ATTR_DEFAULT_FETCH_MODE =^> PDO::FETCH_ASSOC,
echo     PDO::ATTR_EMULATE_PREPARES   =^> false,
echo ];
echo.
echo try {
echo     $pdo = new PDO^($dsn, $user, $pass, $options^);
echo } catch ^(\PDOException $e^) {
echo     http_response_code^(500^);
echo     die^(json_encode^(['error' =^> 'Database connection failed']^)^);
echo }
) > "%TEMP%\config.php"

pscp.exe -batch -pw "%PASSWORD%" "%TEMP%\config.php" %USER%@%SERVER%:%REMOTE_PATH%/config.php
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al subir config.php
    del "%TEMP%\config.php"
    pause
    goto MENU
)
del "%TEMP%\config.php"

echo.
echo [5/7] Subiendo configuracion de Nginx...
if exist "%LOCAL_PATH%timetracker.nginx.conf" (
    pscp.exe -batch -pw "%PASSWORD%" "%LOCAL_PATH%timetracker.nginx.conf" %USER%@%SERVER%:%REMOTE_PATH%/timetracker.nginx.conf
    if %ERRORLEVEL% NEQ 0 (
        echo ADVERTENCIA: Fallo al subir timetracker.nginx.conf
    )
) else (
    echo ADVERTENCIA: No se encuentra timetracker.nginx.conf
)

echo.
echo [6/8] Subiendo CHANGELOG.md...
if exist "%LOCAL_PATH%CHANGELOG.md" (
    pscp.exe -batch -pw "%PASSWORD%" "%LOCAL_PATH%CHANGELOG.md" %USER%@%SERVER%:%REMOTE_PATH%/CHANGELOG.md
    if %ERRORLEVEL% NEQ 0 (
        echo ADVERTENCIA: Fallo al subir CHANGELOG.md
    )
) else (
    echo ADVERTENCIA: No se encuentra CHANGELOG.md
)

echo.
echo [7/8] Subiendo README.md...
if exist "%LOCAL_PATH%README.md" (
    pscp.exe -batch -pw "%PASSWORD%" "%LOCAL_PATH%README.md" %USER%@%SERVER%:%REMOTE_PATH%/README.md
    if %ERRORLEVEL% NEQ 0 (
        echo ADVERTENCIA: Fallo al subir README.md
    )
) else (
    echo ADVERTENCIA: No se encuentra README.md
)

echo.
echo [8/8] Configurando permisos...
plink.exe -batch -pw "%PASSWORD%" %USER%@%SERVER% "cd %REMOTE_PATH% && chmod 644 index.html api.php config.php CHANGELOG.md README.md 2>/dev/null && chown www-data:www-data index.html api.php config.php CHANGELOG.md README.md 2>/dev/null || echo 'Permisos configurados (puede requerir sudo)'"

echo.
echo =========================================================
echo   DESPLIEGUE COMPLETADO
echo =========================================================
echo.
echo Archivos desplegados:
echo   - index.html (con correcciones de filtros y fechas)
echo   - api.php (con validaciones y transacciones)
echo   - config.php (con credenciales de produccion)
echo   - timetracker.nginx.conf
echo   - CHANGELOG.md (registro de cambios v2.0.4.1)
echo   - README.md (manual completo de instalacion y uso)
echo.
echo Siguiente paso:
echo   Si es el primer despliegue, ejecuta setup.php desde el navegador
echo   URL: http://timetracker.resol.dom/setup.php
echo.
echo Backups almacenados en: %REMOTE_PATH%/backups/
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
echo Esta operacion descargara los archivos actuales del servidor
echo y los guardara en una carpeta de backup local.
echo.
echo IMPORTANTE: Los archivos locales actuales NO seran sobrescritos.
echo             Se creara una carpeta: backup_AAAAMMDD_HHMMSS
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

REM Crear carpeta de backup local con timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set BACKUP_FOLDER=%LOCAL_PATH%backup_%datetime:~0,8%_%datetime:~8,6%
mkdir "%BACKUP_FOLDER%"

echo.
echo Carpeta de destino: %BACKUP_FOLDER%
echo.

echo [1/6] Descargando index.html...
pscp.exe -batch -pw "%PASSWORD%" %USER%@%SERVER%:%REMOTE_PATH%/index.html "%BACKUP_FOLDER%\index.html"
if %ERRORLEVEL% NEQ 0 (
    echo ADVERTENCIA: No se pudo descargar index.html
) else (
    echo OK: index.html descargado
)

echo.
echo [2/6] Descargando api.php...
pscp.exe -batch -pw "%PASSWORD%" %USER%@%SERVER%:%REMOTE_PATH%/api.php "%BACKUP_FOLDER%\api.php"
if %ERRORLEVEL% NEQ 0 (
    echo ADVERTENCIA: No se pudo descargar api.php
) else (
    echo OK: api.php descargado
)

echo.
echo [3/6] Descargando config.php...
pscp.exe -batch -pw "%PASSWORD%" %USER%@%SERVER%:%REMOTE_PATH%/config.php "%BACKUP_FOLDER%\config.php"
if %ERRORLEVEL% NEQ 0 (
    echo ADVERTENCIA: No se pudo descargar config.php
) else (
    echo OK: config.php descargado
)

echo.
echo [4/6] Descargando timetracker.nginx.conf...
pscp.exe -batch -pw "%PASSWORD%" %USER%@%SERVER%:%REMOTE_PATH%/timetracker.nginx.conf "%BACKUP_FOLDER%\timetracker.nginx.conf"
if %ERRORLEVEL% NEQ 0 (
    echo ADVERTENCIA: No se pudo descargar timetracker.nginx.conf
) else (
    echo OK: timetracker.nginx.conf descargado
)

echo.
echo [5/7] Descargando CHANGELOG.md...
pscp.exe -batch -pw "%PASSWORD%" %USER%@%SERVER%:%REMOTE_PATH%/CHANGELOG.md "%BACKUP_FOLDER%\CHANGELOG.md"
if %ERRORLEVEL% NEQ 0 (
    echo ADVERTENCIA: No se pudo descargar CHANGELOG.md
) else (
    echo OK: CHANGELOG.md descargado
)

echo.
echo [6/7] Descargando README.md...
pscp.exe -batch -pw "%PASSWORD%" %USER%@%SERVER%:%REMOTE_PATH%/README.md "%BACKUP_FOLDER%\README.md"
if %ERRORLEVEL% NEQ 0 (
    echo ADVERTENCIA: No se pudo descargar README.md
) else (
    echo OK: README.md descargado
)

echo.
echo [7/7] Descargando setup.php (si existe)...
pscp.exe -batch -pw "%PASSWORD%" %USER%@%SERVER%:%REMOTE_PATH%/setup.php "%BACKUP_FOLDER%\setup.php"
if %ERRORLEVEL% NEQ 0 (
    echo INFO: setup.php no existe en servidor (esto es normal si ya fue eliminado)
) else (
    echo OK: setup.php descargado
)

echo.
echo =========================================================
echo   DESCARGA COMPLETADA
echo =========================================================
echo.
echo Archivos descargados en:
echo %BACKUP_FOLDER%
echo.
echo Archivos:
dir /b "%BACKUP_FOLDER%"
echo.
echo Puedes comparar estos archivos con los locales actuales.
echo.
pause
goto MENU

:END
echo.
echo Saliendo...
exit /b 0
