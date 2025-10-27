# Script para crear un sonido tipo DiDi/Uber - sonido de notificacion profesional
# Usa frecuencias armonicas y patrones de notificacion modernos

Write-Host "Creando sonido de notificacion tipo DiDi..." -ForegroundColor Cyan

$outputPath = "assets\sounds\didi_notification.wav"

# Crear carpeta si no existe
New-Item -ItemType Directory -Force -Path "assets\sounds" | Out-Null

try {
    # Parametros del WAV
    $sampleRate = 44100
    $duration = 1.2  # 1.2 segundos total
    $samples = [int]($sampleRate * $duration)
    
    # Crear array de bytes para el audio
    $audioData = New-Object byte[] ($samples * 2)
    
    Write-Host "Generando patron de tonos tipo DiDi..." -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $samples; $i++) {
        $t = $i / $sampleRate
        
        # Patron tipo DiDi: 3 tonos ascendentes con decay
        $sample = 0.0
        
        # Primer tono: 600Hz (0-0.25s)
        if ($t -lt 0.25) {
            $freq1 = 600
            $envelope1 = [Math]::Exp(-$t * 8)  # Decay rapido
            $sample += [Math]::Sin(2 * [Math]::PI * $freq1 * $t) * $envelope1 * 0.4
        }
        
        # Segundo tono: 800Hz (0.3-0.55s)
        if ($t -ge 0.3 -and $t -lt 0.55) {
            $t2 = $t - 0.3
            $freq2 = 800
            $envelope2 = [Math]::Exp(-$t2 * 8)
            $sample += [Math]::Sin(2 * [Math]::PI * $freq2 * $t2) * $envelope2 * 0.4
        }
        
        # Tercer tono: 1000Hz (0.6-0.9s) - mas largo
        if ($t -ge 0.6 -and $t -lt 0.9) {
            $t3 = $t - 0.6
            $freq3 = 1000
            $envelope3 = [Math]::Exp(-$t3 * 5)  # Decay mas lento
            $sample += [Math]::Sin(2 * [Math]::PI * $freq3 * $t3) * $envelope3 * 0.5
        }
        
        # Agregar un poco de armonico para que suene mas rico
        if ($t -lt 0.9) {
            $harmonic = [Math]::Sin(2 * [Math]::PI * 1200 * $t) * 0.1
            $sample += $harmonic * [Math]::Exp(-$t * 4)
        }
        
        # Limitar amplitud
        if ($sample -gt 1.0) { $sample = 1.0 }
        if ($sample -lt -1.0) { $sample = -1.0 }
        
        $sampleInt = [int]($sample * 32767 * 0.8)  # 80% volumen para evitar clipping
        
        # Convertir a little-endian bytes
        $audioData[$i * 2] = $sampleInt -band 0xFF
        $audioData[$i * 2 + 1] = ($sampleInt -shr 8) -band 0xFF
    }
    
    Write-Host "Escribiendo archivo WAV..." -ForegroundColor Yellow
    
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
    
    Write-Host "Sonido tipo DiDi generado exitosamente!" -ForegroundColor Green
    $fileSize = (Get-Item $outputPath).Length
    Write-Host "Tamano: $([Math]::Round($fileSize/1024, 2)) KB" -ForegroundColor Cyan
    Write-Host "Ubicacion: $outputPath" -ForegroundColor Cyan
    
    # Reproducir sonido de prueba
    Write-Host ""
    Write-Host "Reproduciendo sonido de prueba..." -ForegroundColor Cyan
    $player = New-Object System.Media.SoundPlayer $outputPath
    $player.PlaySync()
    
    Write-Host ""
    Write-Host "Perfecto! Ahora actualiza el codigo y ejecuta 'flutter run'" -ForegroundColor Green
    Write-Host "El sonido tiene 3 tonos ascendentes (600Hz -> 800Hz -> 1000Hz)" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error al generar sonido: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
