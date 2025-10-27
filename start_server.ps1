# Script para iniciar el servidor PHP
Write-Host "🚀 Iniciando servidor PHP en puerto 8000..." -ForegroundColor Cyan

# Cambiar al directorio del backend
Set-Location "C:\Flutter\ping_go\pingo\backend"

# Iniciar el servidor
Write-Host "📡 Servidor PHP corriendo en http://localhost:8000" -ForegroundColor Green
Write-Host "📋 Endpoints disponibles:" -ForegroundColor Yellow
Write-Host "  - GET  http://localhost:8000/admin/get_pricing_configs.php" -ForegroundColor White
Write-Host "  - POST http://localhost:8000/admin/update_pricing_config.php" -ForegroundColor White
Write-Host "`n⚠️  Presiona Ctrl+C para detener el servidor`n" -ForegroundColor Red

# Ejecutar servidor
php -S localhost:8000
