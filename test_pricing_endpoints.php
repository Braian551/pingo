<?php
/**
 * Script de prueba para los endpoints de pricing
 * Ejecutar: php test_pricing_endpoints.php
 */

$baseUrl = 'http://localhost:8000';

echo "===========================================\n";
echo "PRUEBA DE ENDPOINTS DE PRICING\n";
echo "===========================================\n\n";

// 1. Probar GET de configuraciones
echo "1. Probando GET /admin/get_pricing_configs.php\n";
echo "-------------------------------------------\n";

$ch = curl_init("$baseUrl/admin/get_pricing_configs.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Código HTTP: $httpCode\n";
if ($httpCode === 200) {
    $data = json_decode($response, true);
    echo "✅ Éxito\n";
    echo "Total de configuraciones: " . $data['stats']['total'] . "\n";
    echo "Configuraciones activas: " . $data['stats']['activos'] . "\n";
    
    if (!empty($data['data'])) {
        echo "\nPrimera configuración:\n";
        $config = $data['data'][0];
        echo "  - Tipo: " . $config['tipo_vehiculo'] . "\n";
        echo "  - Tarifa Base: $" . $config['tarifa_base'] . "\n";
        echo "  - Costo por Km: $" . $config['costo_por_km'] . "\n";
        echo "  - Activo: " . ($config['activo'] ? 'Sí' : 'No') . "\n";
    }
} else {
    echo "❌ Error\n";
    echo "Respuesta: $response\n";
}

echo "\n";

// 2. Probar UPDATE de configuración
echo "2. Probando POST /admin/update_pricing_config.php\n";
echo "-------------------------------------------\n";

// Primero obtener una configuración existente
$ch = curl_init("$baseUrl/admin/get_pricing_configs.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

$data = json_decode($response, true);
if (!empty($data['data'])) {
    $configId = $data['data'][0]['id'];
    
    // Preparar datos de actualización (sin cambiar realmente los valores)
    $updateData = [
        'id' => $configId,
        'tarifa_base' => $data['data'][0]['tarifa_base'],
        'costo_por_km' => $data['data'][0]['costo_por_km'],
        'costo_por_minuto' => $data['data'][0]['costo_por_minuto'],
        'tarifa_minima' => $data['data'][0]['tarifa_minima'],
        'recargo_hora_pico' => $data['data'][0]['recargo_hora_pico'],
        'recargo_nocturno' => $data['data'][0]['recargo_nocturno'],
        'recargo_festivo' => $data['data'][0]['recargo_festivo'],
        'comision_plataforma' => $data['data'][0]['comision_plataforma']
    ];
    
    $ch = curl_init("$baseUrl/admin/update_pricing_config.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($updateData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "Código HTTP: $httpCode\n";
    if ($httpCode === 200) {
        $data = json_decode($response, true);
        echo "✅ Éxito\n";
        echo "Mensaje: " . $data['message'] . "\n";
    } else {
        echo "❌ Error\n";
        echo "Respuesta: $response\n";
    }
} else {
    echo "❌ No hay configuraciones para probar el UPDATE\n";
}

echo "\n===========================================\n";
echo "PRUEBAS COMPLETADAS\n";
echo "===========================================\n";
?>
