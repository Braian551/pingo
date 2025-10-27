# Script de PowerShell para probar el endpoint de solicitudes pendientes

Write-Host "==========================================================`n" -ForegroundColor Cyan
Write-Host "TEST HTTP: Get Solicitudes Pendientes" -ForegroundColor Cyan
Write-Host "==========================================================`n" -ForegroundColor Cyan

# Parámetros del conductor (mismo del test PHP exitoso)
$conductorId = 11
$latitudActual = 4.6097
$longitudActual = -74.0817
$radioKm = 10.0

Write-Host "Parametros de busqueda:" -ForegroundColor Yellow
Write-Host "   - Conductor ID: $conductorId"
Write-Host "   - Latitud: $latitudActual"
Write-Host "   - Longitud: $longitudActual"
Write-Host "   - Radio: $radioKm km`n"

# Crear el body JSON
$body = @{
    conductor_id = $conductorId
    latitud_actual = $latitudActual
    longitud_actual = $longitudActual
    radio_km = $radioKm
} | ConvertTo-Json

Write-Host "Enviando peticion a: http://10.0.2.2/pingo/backend/conductor/get_solicitudes_pendientes.php`n" -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest `
        -Uri "http://10.0.2.2/pingo/backend/conductor/get_solicitudes_pendientes.php" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing

    Write-Host "Respuesta recibida (Status: $($response.StatusCode))`n" -ForegroundColor Green
    
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "Datos de respuesta:" -ForegroundColor Cyan
    Write-Host "   - Success: $($data.success)"
    Write-Host "   - Total solicitudes: $($data.total)"
    Write-Host "   - Conductor Lat: $($data.conductor_lat)"
    Write-Host "   - Conductor Lng: $($data.conductor_lng)"
    Write-Host "   - Radio busqueda: $($data.radio_busqueda_km) km`n"
    
    if ($data.solicitudes -and $data.solicitudes.Count -gt 0) {
        Write-Host "Solicitudes encontradas: $($data.solicitudes.Count)`n" -ForegroundColor Green
        
        foreach ($solicitud in $data.solicitudes) {
            Write-Host "   Solicitud ID: $($solicitud.id)" -ForegroundColor Yellow
            Write-Host "      - Cliente: $($solicitud.nombre_usuario) (ID: $($solicitud.usuario_id))"
            Write-Host "      - Telefono: $($solicitud.telefono_usuario)"
            Write-Host "      - Origen: $($solicitud.direccion_origen)"
            Write-Host "      - Destino: $($solicitud.direccion_destino)"
            Write-Host "      - Distancia viaje: $($solicitud.distancia_km) km"
            Write-Host "      - Distancia conductor-origen: $($solicitud.distancia_conductor_origen) km"
            Write-Host "      - Precio estimado: $($solicitud.precio_estimado) COP"
            Write-Host "      - Tiempo: $($solicitud.duracion_minutos) min`n"
        }
    }
    else {
        Write-Host "No se encontraron solicitudes`n" -ForegroundColor Yellow
    }
    
    Write-Host "`nJSON completo de respuesta:" -ForegroundColor Cyan
    Write-Host $($response.Content) -ForegroundColor Gray
    
}
catch {
    Write-Host "`nERROR: $($_.Exception.Message)`n" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "Respuesta del servidor:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor Gray
    }
}

Write-Host "`n==========================================================`n" -ForegroundColor Cyan
