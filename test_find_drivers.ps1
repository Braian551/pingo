$body = @{
    latitud = 4.6097
    longitud = -74.0817
    tipo_vehiculo = "moto"
    radio_km = 5.0
} | ConvertTo-Json

Write-Host "Probando endpoint find_nearby_drivers..." -ForegroundColor Yellow
Write-Host "Datos enviados: $body" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri "http://localhost/pingo/backend/user/find_nearby_drivers.php" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 5 -ErrorAction Stop
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Respuesta:" -ForegroundColor Cyan
    $result = $response.Content | ConvertFrom-Json
    $result | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}
