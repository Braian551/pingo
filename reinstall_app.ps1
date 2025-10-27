# Script para reinstalar la app y solucionar problemas de sonido
# Uso: .\reinstall_app.ps1

Write-Host "🔧 Reinstalando PingGo para solucionar problemas de audio..." -ForegroundColor Cyan
Write-Host ""

# Paso 1: Limpiar todo
Write-Host "1️⃣ Limpiando cache de Flutter..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al limpiar Flutter" -ForegroundColor Red
    exit 1
}

# Paso 2: Desinstalar app
Write-Host ""
Write-Host "2️⃣ Desinstalando app del dispositivo..." -ForegroundColor Yellow
adb uninstall com.example.ping_go
# Ignorar error si la app no está instalada

# Paso 3: Limpiar build de Android
Write-Host ""
Write-Host "3️⃣ Limpiando build de Gradle..." -ForegroundColor Yellow
Set-Location android
.\gradlew clean | Out-Null
Set-Location ..

# Paso 4: Reinstalar dependencias
Write-Host ""
Write-Host "4️⃣ Reinstalando dependencias..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al obtener dependencias" -ForegroundColor Red
    exit 1
}

# Paso 5: Verificar archivos de sonido
Write-Host ""
Write-Host "5️⃣ Verificando archivos de sonido..." -ForegroundColor Yellow
$soundFile = "assets\sounds\request_notification.wav"
if (Test-Path $soundFile) {
    Write-Host "   ✅ $soundFile existe" -ForegroundColor Green
} else {
    Write-Host "   ❌ $soundFile NO EXISTE" -ForegroundColor Red
    exit 1
}

# Paso 6: Compilar e instalar
Write-Host ""
Write-Host "6️⃣ Compilando e instalando app..." -ForegroundColor Yellow
Write-Host "   (Esto puede tomar varios minutos...)" -ForegroundColor Gray

flutter run --no-hot-reload

Write-Host ""
Write-Host "✅ ¡Proceso completado!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Pasos siguientes:" -ForegroundColor Cyan
Write-Host "   1. Abrir la app en el dispositivo"
Write-Host "   2. Navegar a Conductor → Disponibilidad"
Write-Host "   3. Presionar el botón de prueba de sonido (icono azul)"
Write-Host "   4. Verificar logs en la consola"
Write-Host ""
Write-Host "💡 Tip: Asegúrate de tener el volumen del dispositivo al máximo" -ForegroundColor Yellow
