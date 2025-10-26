$body = @{
    usuario_id = 2
    latitud_origen = 4.6097
    longitud_origen = -74.0817
    direccion_origen = "Calle 123, Bogotá"
    latitud_destino = 4.6533
    longitud_destino = -74.0836
    direccion_destino = "Carrera 45, Chapinero"
    tipo_servicio = "viaje"
    tipo_vehiculo = "moto"
    distancia_km = 5.5
    duracion_minutos = 15
    precio_estimado = 15000
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost/pingo/backend/user/create_trip_request.php" -Method POST -ContentType "application/json" -Body $body
    Write-Host "Status Code: $($response.StatusCode)"
    Write-Host "Response:"
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody"
    }
}
