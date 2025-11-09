Get-ChildItem -Path "lib" -Recurse -Include "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace 'Ã¡', 'á'
    $content = $content -replace 'Ã©', 'é'
    $content = $content -replace 'Ã­', 'í'
    $content = $content -replace 'Ã³', 'ó'
    $content = $content -replace 'Ãº', 'ú'
    $content = $content -replace 'Ã±', 'ñ'
    $content = $content -replace 'Ã', 'í'
    [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed: $($_.Name)"
}