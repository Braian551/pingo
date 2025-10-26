# Script para verificar que el servidor este corriendo
Write-Host "=== Verificacion del Servidor Backend ===" -ForegroundColor Green
Write-Host ""

# 1. Verificar si el puerto 80 esta en uso
Write-Host "1. Verificando puerto 80..." -ForegroundColor Yellow
$port80 = netstat -ano | findstr :80 | Select-String "LISTENING"
if ($port80) {
    Write-Host "   OK Puerto 80 esta en uso (servidor corriendo)" -ForegroundColor Green
} else {
    Write-Host "   ERROR Puerto 80 NO esta en uso" -ForegroundColor Red
    Write-Host "   -> Inicia Laragon o tu servidor web" -ForegroundColor Yellow
}
Write-Host ""

# 2. Probar conexion HTTP al backend
Write-Host "2. Probando conexion HTTP..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost/pingo/backend/verify_system.php" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   OK Backend accesible: Status $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ERROR No se puede acceder al backend" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# 3. Probar endpoint de creacion de solicitud
Write-Host "3. Probando endpoint de solicitud de viaje..." -ForegroundColor Yellow
$testData = @{
    usuario_id = 2
    latitud_origen = 4.6097
    longitud_origen = -74.0817
    direccion_origen = "Calle 123, Bogota"
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
    $response = Invoke-WebRequest -Uri "http://localhost/pingo/backend/user/create_trip_request.php" -Method POST -ContentType "application/json" -Body $testData -TimeoutSec 5 -ErrorAction Stop
    $result = $response.Content | ConvertFrom-Json
    if ($result.success) {
        Write-Host "   OK Endpoint funcionando correctamente" -ForegroundColor Green
        Write-Host "   Solicitud ID: $($result.solicitud_id)" -ForegroundColor Cyan
        Write-Host "   Conductores encontrados: $($result.conductores_encontrados)" -ForegroundColor Cyan
    } else {
        Write-Host "   ERROR Endpoint respondio con error: $($result.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ERROR al probar endpoint" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}
Write-Host ""

# 4. Verificar URL del emulador (10.0.2.2)
Write-Host "4. Informacion para el emulador Android:" -ForegroundColor Yellow
Write-Host "   URL a usar: http://10.0.2.2/pingo/backend" -ForegroundColor Cyan
Write-Host "   (10.0.2.2 es el alias del localhost en el emulador)" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Fin de la verificacion ===" -ForegroundColor Green
