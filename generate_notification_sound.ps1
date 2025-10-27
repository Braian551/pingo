# Script para generar un sonido de notificación simple y efectivo para Android
# Usa FFmpeg para crear un tono de 800Hz que es audible en todos los dispositivos

Write-Host "🔊 Generando sonido de notificación..." -ForegroundColor Cyan

# Verificar si FFmpeg está instalado
$ffmpegPath = Get-Command ffmpeg -ErrorAction SilentlyContinue

if (-not $ffmpegPath) {
    Write-Host "❌ FFmpeg no está instalado." -ForegroundColor Red
    Write-Host "📥 Descarga FFmpeg desde: https://ffmpeg.org/download.html" -ForegroundColor Yellow
    Write-Host "💡 O usa Chocolatey: choco install ffmpeg" -ForegroundColor Yellow
    exit 1
}

$outputPath = "assets/sounds/request_notification.wav"

# Crear carpeta si no existe
New-Item -ItemType Directory -Force -Path "assets/sounds" | Out-Null

# Generar un sonido de notificación con 3 tonos cortos
# Frecuencia 800Hz, duración 1.5 segundos
# Patrón: beep-beep-beep (como notificación de Uber)
ffmpeg -y `
    -f lavfi `
    -i "sine=frequency=800:duration=0.15,sine=frequency=800:duration=0.15,sine=frequency=1000:duration=0.2" `
    -filter_complex "[0:a][1:a][2:a]concat=n=3:v=0:a=1,volume=0.8" `
    -ar 44100 `
    -ac 1 `
    -acodec pcm_s16le `
    $outputPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Sonido generado exitosamente: $outputPath" -ForegroundColor Green
    Write-Host "🎵 Reproduciendo sonido de prueba..." -ForegroundColor Cyan
    
    # Intentar reproducir el sonido (Windows)
    $player = New-Object System.Media.SoundPlayer $outputPath
    $player.PlaySync()
    
    Write-Host "✅ ¡Listo! Ejecuta 'flutter run' para probar en la app" -ForegroundColor Green
} else {
    Write-Host "❌ Error al generar el sonido" -ForegroundColor Red
    exit 1
}
