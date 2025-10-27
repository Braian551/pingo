<?php
/**
 * Script de prueba para verificar la cancelación de viajes
 */

$baseUrl = 'http://localhost/pingo/backend';

echo "🧪 Prueba de Cancelación de Viaje\n";
echo "==================================\n\n";

// ID de la última solicitud creada (ajustar según sea necesario)
$solicitudId = 19; // Cambiar por el ID de tu solicitud de prueba

echo "📋 Cancelando solicitud ID: $solicitudId\n";

$data = [
    'solicitud_id' => $solicitudId
];

$ch = curl_init("$baseUrl/user/cancel_trip_request.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "\n📥 Respuesta del servidor:\n";
echo "Status Code: $httpCode\n";
echo "Body: $response\n\n";

$result = json_decode($response, true);

if ($result && $result['success']) {
    echo "✅ Solicitud cancelada exitosamente\n";
    echo "Mensaje: " . $result['message'] . "\n";
} else {
    echo "❌ Error al cancelar la solicitud\n";
    if (isset($result['message'])) {
        echo "Mensaje de error: " . $result['message'] . "\n";
    }
}
