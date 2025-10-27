# Script para iniciar el servidor PHP y probar los endpoints de pricing
# Ejecutar: .\test_pricing_api.ps1

Write-Host "===========================================`n" -ForegroundColor Cyan
Write-Host "INICIANDO SERVIDOR PHP Y PROBANDO API" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan

# Verificar si el puerto 8000 está en uso
$port8000 = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue

if ($port8000) {
    Write-Host "✅ El servidor ya está corriendo en el puerto 8000" -ForegroundColor Green
} else {
    Write-Host "🚀 Iniciando servidor PHP en el puerto 8000..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'C:\Flutter\ping_go\pingo\backend'; php -S localhost:8000" -WindowStyle Normal
    Start-Sleep -Seconds 3
}

Write-Host "`n📋 Ejecutando pruebas de endpoints...`n" -ForegroundColor Cyan

# Ejecutar script de prueba PHP
cd C:\Flutter\ping_go
php test_pricing_endpoints.php

Write-Host "`n✨ Pruebas completadas!" -ForegroundColor Green
Write-Host "`nPuedes acceder a los endpoints en:" -ForegroundColor Yellow
Write-Host "  - GET  http://localhost:8000/admin/get_pricing_configs.php" -ForegroundColor White
Write-Host "  - POST http://localhost:8000/admin/update_pricing_config.php" -ForegroundColor White

Write-Host "`nPara probar desde Flutter, inicia la app con:" -ForegroundColor Yellow
Write-Host "  flutter run" -ForegroundColor White

Read-Host "`nPresiona Enter para continuar"
