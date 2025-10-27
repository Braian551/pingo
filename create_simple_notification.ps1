# Script simple para generar un tono de notificación usando .NET sin FFmpeg
# Genera 3 beeps cortos en formato WAV

Write-Host "🔊 Generando sonido de notificación..." -ForegroundColor Cyan

$outputPath = "assets\sounds\request_notification.wav"

# Crear carpeta si no existe
New-Item -ItemType Directory -Force -Path "assets\sounds" | Out-Null

try {
    # Usar System.Media.SoundPlayer para generar el archivo
    Add-Type -AssemblyName System.Windows.Forms
    
    # Generar un beep simple usando Console.Beep guardado en memoria
    # Nota: Este enfoque es básico, pero garantiza compatibilidad
    
    Write-Host "🎵 Generando tono de 800Hz..." -ForegroundColor Yellow
    
    # Parámetros del WAV
    $sampleRate = 44100
    $frequency = 800
    $duration = 1.5
    $amplitude = 0.5
    
    $samples = [int]($sampleRate * $duration)
    
    # Crear array de bytes para el audio
    $audioData = New-Object byte[] ($samples * 2)
    
    for ($i = 0; $i -lt $samples; $i++) {
        # Generar onda sinusoidal
        $t = $i / $sampleRate
        
        # Crear patrón de 3 beeps
        $envelope = 0
        if ($t -lt 0.2) {
            $envelope = 1
        } elseif ($t -gt 0.3 -and $t -lt 0.5) {
            $envelope = 1
        } elseif ($t -gt 0.6 -and $t -lt 0.9) {
            $envelope = 1
        }
        
        $sample = [Math]::Sin(2 * [Math]::PI * $frequency * $t) * $amplitude * $envelope
        $sampleInt = [int]($sample * 32767)
        
        # Convertir a little-endian bytes
        $audioData[$i * 2] = $sampleInt -band 0xFF
        $audioData[$i * 2 + 1] = ($sampleInt -shr 8) -band 0xFF
    }
    
    # Crear header WAV
    $stream = [System.IO.File]::Open($outputPath, [System.IO.FileMode]::Create)
    $writer = New-Object System.IO.BinaryWriter($stream)
    
    # RIFF header
    $writer.Write([char[]]"RIFF")
    $writer.Write([uint32](36 + $audioData.Length))
    $writer.Write([char[]]"WAVE")
    
    # fmt chunk
    $writer.Write([char[]]"fmt ")
    $writer.Write([uint32]16) # chunk size
    $writer.Write([uint16]1)  # PCM format
    $writer.Write([uint16]1)  # mono
    $writer.Write([uint32]$sampleRate)
    $writer.Write([uint32]($sampleRate * 2)) # byte rate
    $writer.Write([uint16]2) # block align
    $writer.Write([uint16]16) # bits per sample
    
    # data chunk
    $writer.Write([char[]]"data")
    $writer.Write([uint32]$audioData.Length)
    $writer.Write($audioData)
    
    $writer.Close()
    $stream.Close()
    
    Write-Host "✅ Sonido generado exitosamente: $outputPath" -ForegroundColor Green
    $fileSize = (Get-Item $outputPath).Length
    Write-Host "📊 Tamaño: $fileSize bytes" -ForegroundColor Cyan
    
    # Reproducir sonido de prueba
    Write-Host "🎵 Reproduciendo sonido de prueba..." -ForegroundColor Cyan
    $player = New-Object System.Media.SoundPlayer $outputPath
    $player.PlaySync()
    
    Write-Host "✅ ¡Listo! Ejecuta 'flutter run' para probar en la app" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
