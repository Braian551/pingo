# Script para copiar el backend a Laragon
# Ejecutar desde la raíz del proyecto ping_go

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Configuración Local de PinGo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Rutas
$proyectoActual = $PSScriptRoot
$backendSource = Join-Path $proyectoActual "backend-deploy"
$laragonWww = "C:\laragon\www"
$backendDest = Join-Path $laragonWww "ping_go\backend-deploy"

Write-Host "📂 Verificando rutas..." -ForegroundColor Yellow
Write-Host "   Origen: $backendSource"
Write-Host "   Destino: $backendDest"
Write-Host ""

# Verificar que existe el directorio source
if (-not (Test-Path $backendSource)) {
    Write-Host "❌ Error: No se encuentra la carpeta backend-deploy" -ForegroundColor Red
    Write-Host "   Ruta buscada: $backendSource" -ForegroundColor Red
    exit 1
}

# Verificar que Laragon está instalado
if (-not (Test-Path $laragonWww)) {
    Write-Host "❌ Error: No se encuentra Laragon" -ForegroundColor Red
    Write-Host "   Ruta esperada: $laragonWww" -ForegroundColor Red
    Write-Host "   ¿Está instalado Laragon?" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Rutas verificadas correctamente" -ForegroundColor Green
Write-Host ""

# Crear directorio si no existe
$parentDir = Split-Path $backendDest -Parent
if (-not (Test-Path $parentDir)) {
    Write-Host "📁 Creando directorio: $parentDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

# Preguntar si desea sobrescribir si ya existe
if (Test-Path $backendDest) {
    Write-Host "⚠️  El backend ya existe en Laragon" -ForegroundColor Yellow
    $respuesta = Read-Host "¿Deseas sobrescribir? (S/N)"
    
    if ($respuesta -ne "S" -and $respuesta -ne "s") {
        Write-Host "❌ Operación cancelada" -ForegroundColor Red
        exit 0
    }
    
    Write-Host "🗑️  Eliminando versión anterior..." -ForegroundColor Yellow
    Remove-Item -Path $backendDest -Recurse -Force
}

# Copiar archivos
Write-Host "📦 Copiando archivos al directorio de Laragon..." -ForegroundColor Yellow
Write-Host "   Esto puede tardar unos segundos..." -ForegroundColor Gray
Write-Host ""

try {
    Copy-Item -Path $backendSource -Destination $backendDest -Recurse -Force
    Write-Host "✅ Archivos copiados exitosamente" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al copiar archivos: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   ¡Configuración Completada!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Asegúrate de que Laragon esté corriendo" -ForegroundColor White
Write-Host "   (Apache y MySQL deben estar activos)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Crea la base de datos 'pingo' en HeidiSQL o phpMyAdmin" -ForegroundColor White
Write-Host ""
Write-Host "3. Importa el archivo SQL:" -ForegroundColor White
Write-Host "   $proyectoActual\basededatos (2).sql" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Verifica que el backend funcione:" -ForegroundColor White
Write-Host "   http://localhost/ping_go/backend-deploy/health.php" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Instala dependencias PHP (si es necesario):" -ForegroundColor White
Write-Host "   cd $backendDest" -ForegroundColor Gray
Write-Host "   composer install" -ForegroundColor Gray
Write-Host ""

Write-Host "📚 Documentación completa en:" -ForegroundColor Yellow
Write-Host "   docs\SETUP_LARAGON.md" -ForegroundColor Cyan
Write-Host "   docs\CONFIGURACION_ENTORNOS.md" -ForegroundColor Cyan
Write-Host ""

# Preguntar si desea abrir el navegador
$abrirNavegador = Read-Host "¿Deseas abrir el navegador para verificar? (S/N)"
if ($abrirNavegador -eq "S" -or $abrirNavegador -eq "s") {
    Start-Process "http://localhost/ping_go/backend-deploy/health.php"
}

Write-Host ""
Write-Host "✨ ¡Listo para desarrollar!" -ForegroundColor Green
Write-Host ""
