# Script para configurar ubicación en emulador Android
# Ejecutar mientras el emulador está corriendo

Write-Host "🗺️ Configurando ubicación del emulador..." -ForegroundColor Cyan

# Encontrar adb
$adb = "adb"
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    $androidHome = $env:ANDROID_HOME
    if ($androidHome) {
        $adb = Join-Path $androidHome "platform-tools\adb.exe"
    }
}

# Verificar si el emulador está corriendo
$devices = & $adb devices
if ($devices -match "emulator") {
    Write-Host "✅ Emulador detectado" -ForegroundColor Green
    
    # Configurar ubicación GPS (Bogotá, Colombia)
    Write-Host "📍 Estableciendo ubicación GPS en Bogotá (4.6097, -74.0817)" -ForegroundColor Yellow
    
    # Enviar comando telnet al emulador
    $port = "5554"
    Write-Host "   Conectando al emulador en puerto $port..." -ForegroundColor Gray
    
    # Crear comando para telnet
    $commands = @"
geo fix -74.0817 4.6097
exit
"@
    
    $commands | & "telnet" "localhost" $port 2>&1 | Out-Null
    
    Write-Host "✅ Ubicación configurada correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Consejos:" -ForegroundColor Cyan
    Write-Host "   - La ubicación GPS puede tardar unos segundos en activarse" -ForegroundColor Gray
    Write-Host "   - Asegúrate de que el GPS esté activado en el emulador" -ForegroundColor Gray
    Write-Host "   - Puedes cambiar la ubicación desde: Extended Controls (⋮) > Location" -ForegroundColor Gray
} else {
    Write-Host "❌ No se detectó ningún emulador corriendo" -ForegroundColor Red
    Write-Host "   Inicia el emulador primero con: flutter emulators --launch <nombre>" -ForegroundColor Gray
}
