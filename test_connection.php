<?php
/**
 * Script de prueba rápida de conexión
 * Ejecutar: php test_connection.php
 */

echo "===========================================\n";
echo "PRUEBA DE CONEXIÓN - PRICING API\n";
echo "===========================================\n\n";

// Probar conexión a la base de datos
echo "1. Probando conexión a la base de datos...\n";
echo "-------------------------------------------\n";

try {
    require_once 'pingo/backend/config/database.php';
    $database = new Database();
    $conn = $database->getConnection();
    
    echo "✅ Conexión a base de datos: EXITOSA\n";
    
    // Verificar tabla configuracion_precios
    echo "\n2. Verificando tabla configuracion_precios...\n";
    echo "-------------------------------------------\n";
    
    $query = "SELECT COUNT(*) as total FROM configuracion_precios";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "✅ Tabla encontrada\n";
    echo "📊 Total de registros: " . $result['total'] . "\n";
    
    // Mostrar estructura de la tabla
    echo "\n3. Verificando estructura de la tabla...\n";
    echo "-------------------------------------------\n";
    
    $query = "SHOW COLUMNS FROM configuracion_precios";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "📋 Columnas encontradas (" . count($columns) . "):\n";
    foreach ($columns as $col) {
        echo "  - " . $col['Field'] . " (" . $col['Type'] . ")\n";
    }
    
    // Obtener una configuración de ejemplo
    echo "\n4. Consultando configuración de ejemplo...\n";
    echo "-------------------------------------------\n";
    
    $query = "SELECT * FROM configuracion_precios WHERE activo = 1 LIMIT 1";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $config = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($config) {
        echo "✅ Configuración encontrada:\n";
        echo "  - ID: " . $config['id'] . "\n";
        echo "  - Tipo: " . $config['tipo_vehiculo'] . "\n";
        echo "  - Tarifa Base: $" . $config['tarifa_base'] . "\n";
        echo "  - Costo por Km: $" . $config['costo_por_km'] . "\n";
        echo "  - Activo: " . ($config['activo'] ? 'Sí' : 'No') . "\n";
    } else {
        echo "⚠️  No se encontraron configuraciones activas\n";
    }
    
    echo "\n===========================================\n";
    echo "✅ TODAS LAS PRUEBAS PASARON\n";
    echo "===========================================\n";
    echo "\n💡 Para iniciar el servidor PHP, ejecuta:\n";
    echo "   powershell -ExecutionPolicy Bypass -File start_server.ps1\n\n";
    
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    echo "\n🔧 Soluciones posibles:\n";
    echo "  1. Verifica que XAMPP/MySQL esté corriendo\n";
    echo "  2. Verifica las credenciales en config/database.php\n";
    echo "  3. Verifica que la base de datos 'pingo' exista\n";
}
?>
