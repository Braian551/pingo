@echo off
REM Script para copiar el backend a Laragon
REM Ejecutar desde la raíz del proyecto viax

color 0B
echo ========================================
echo    Configuracion Local de Viax
echo ========================================
echo.

REM Rutas
set BACKEND_SOURCE=%~dp0backend
set LARAGON_WWW=C:\laragon\www
set BACKEND_DEST=%LARAGON_WWW%\viax\backend

echo Verificando rutas...
echo    Origen: %BACKEND_SOURCE%
echo    Destino: %BACKEND_DEST%
echo.

REM Verificar que existe el directorio source
if not exist "%BACKEND_SOURCE%" (
    color 0C
    echo ERROR: No se encuentra la carpeta backend
    echo    Ruta buscada: %BACKEND_SOURCE%
    pause
    exit /b 1
)

REM Verificar que Laragon está instalado
if not exist "%LARAGON_WWW%" (
    color 0C
    echo ERROR: No se encuentra Laragon
    echo    Ruta esperada: %LARAGON_WWW%
    echo    Esta instalado Laragon?
    pause
    exit /b 1
)

color 0A
echo Rutas verificadas correctamente
echo.

REM Crear directorio si no existe
if not exist "%LARAGON_WWW%\viax" (
    echo Creando directorio: %LARAGON_WWW%\viax
    mkdir "%LARAGON_WWW%\viax"
)

REM Preguntar si desea sobrescribir si ya existe
if exist "%BACKEND_DEST%" (
    color 0E
    echo ADVERTENCIA: El backend ya existe en Laragon
    set /p RESPUESTA="Deseas sobrescribir? (S/N): "
    
    if /i not "%RESPUESTA%"=="S" (
        color 0C
        echo Operacion cancelada
        pause
        exit /b 0
    )
    
    echo Eliminando version anterior...
    rmdir /s /q "%BACKEND_DEST%"
)

REM Copiar archivos
color 0B
echo Copiando archivos al directorio de Laragon...
echo    Esto puede tardar unos segundos...
echo.

xcopy "%BACKEND_SOURCE%" "%BACKEND_DEST%\" /E /I /H /Y >nul

if %ERRORLEVEL% EQU 0 (
    color 0A
    echo Archivos copiados exitosamente
) else (
    color 0C
    echo ERROR al copiar archivos
    pause
    exit /b 1
)

echo.
color 0B
echo ========================================
echo    Configuracion Completada!
echo ========================================
echo.

color 0E
echo Proximos pasos:
echo.
color 0F
echo 1. Asegurate de que Laragon este corriendo
echo    (Apache y MySQL deben estar activos)
echo.
echo 2. Crea la base de datos 'viax' en HeidiSQL o phpMyAdmin
echo.
echo 3. Importa el archivo SQL:
echo    %~dp0basededatosfinal.sql
echo.
echo 4. Verifica que el backend funcione:
color 0B
echo    http://localhost/viax/backend/health.php
echo.
color 0F
echo 5. Instala dependencias PHP (si es necesario):
echo    cd %BACKEND_DEST%
echo    composer install
echo.

color 0E
echo Documentacion completa en:
color 0B
echo    docs\SETUP_LARAGON.md
echo    docs\CONFIGURACION_ENTORNOS.md
echo.

REM Preguntar si desea abrir el navegador
color 0F
set /p ABRIR_NAV="Deseas abrir el navegador para verificar? (S/N): "
if /i "%ABRIR_NAV%"=="S" (
    start http://localhost/viax/backend/health.php
)

echo.
color 0A
echo Listo para desarrollar!
echo.
color 0F
pause
