@echo off
echo Creando repositorio separado para el backend...

REM Crear nuevo repo en GitHub primero desde el navegador
echo.
echo PASO 1: Ve a https://github.com/new
echo - Repository name: pinggo-backend
echo - Description: Backend API for PingGo app
echo - Public/Private: según prefieras
echo - NO marques "Add a README file"
echo.
pause

REM Inicializar git en la carpeta backend-deploy
cd backend-deploy
git init
git add .
git commit -m "Initial backend deployment for PingGo"

REM Configurar remote (cambiar TU_USUARIO por tu username de GitHub)
echo.
echo PASO 2: Configurando remote...
echo Reemplaza 'TU_USUARIO' con tu username de GitHub
set /p username="Tu username de GitHub: "
git remote add origin https://github.com/%username%/pinggo-backend.git

REM Push
echo.
echo PASO 3: Subiendo a GitHub...
git push -u origin main

echo.
echo ✅ Repositorio backend creado exitosamente!
echo Ahora puedes deployarlo en Railway conectando el repo 'pinggo-backend'
pause