# Script para corregir constantes inválidas
$files = @(
    "c:\Flutter\viax\lib\src\features\admin\presentation\screens\statistics_screen.dart",
    "c:\Flutter\viax\lib\src\features\admin\presentation\screens\audit_logs_screen.dart",
    "c:\Flutter\viax\lib\src\features\admin\presentation\screens\conductores_documentos_screen.dart",
    "c:\Flutter\viax\lib\src\features\admin\presentation\screens\pricing_management_screen.dart",
    "c:\Flutter\viax\lib\src\features\admin\presentation\screens\users_management_screen.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Corrigiendo constantes inválidas en: $file"

        # Leer contenido
        $content = Get-Content $file -Raw

        # Quitar const de expresiones específicas que causan errores
        $content = $content -replace "const AppColors\.primary", "AppColors.primary"
        $content = $content -replace "const AppColors\.primary\.withOpacity", "AppColors.primary.withOpacity"
        $content = $content -replace "const TextStyle\(color: Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color", "TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color"
        $content = $content -replace "const Icon\([^)]*color: Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color", "Icon("
        $content = $content -replace "const Divider\(color: Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color", "Divider(color: Theme.of(context).textTheme.bodyLarge?.color"

        # Guardar archivo
        Set-Content $file $content -Encoding UTF8

        Write-Host "Corregido: $file"
    } else {
        Write-Host "Archivo no encontrado: $file"
    }
}

Write-Host "Corrección de constantes inválidas completada."