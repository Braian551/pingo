<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validar datos requeridos
    if (!isset($data['latitud']) || !isset($data['longitud']) || !isset($data['tipo_vehiculo'])) {
        throw new Exception('Datos requeridos: latitud, longitud, tipo_vehiculo');
    }
    
    $latitud = $data['latitud'];
    $longitud = $data['longitud'];
    $tipoVehiculo = $data['tipo_vehiculo'];
    $radioKm = $data['radio_km'] ?? 5.0;
    
    $database = new Database();
    $db = $database->getConnection();
    
    // Buscar conductores cercanos disponibles usando la fórmula de Haversine
    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.nombre,
            u.telefono,
            u.latitud_actual,
            u.longitud_actual,
            dc.tipo_vehiculo,
            dc.marca_vehiculo,
            dc.modelo_vehiculo,
            dc.placa_vehiculo,
            dc.color_vehiculo,
            dc.calificacion_promedio,
            dc.total_viajes,
            (6371 * acos(
                cos(radians(?)) * cos(radians(u.latitud_actual)) *
                cos(radians(u.longitud_actual) - radians(?)) +
                sin(radians(?)) * sin(radians(u.latitud_actual))
            )) AS distancia_km
        FROM usuarios u
        INNER JOIN detalles_conductor dc ON u.id = dc.usuario_id
        WHERE u.tipo_usuario = 'conductor'
        AND u.disponibilidad = 1
        AND dc.estado_verificacion = 'aprobado'
        AND dc.tipo_vehiculo = ?
        AND u.latitud_actual IS NOT NULL
        AND u.longitud_actual IS NOT NULL
        HAVING distancia_km <= ?
        ORDER BY distancia_km ASC
        LIMIT 20
    ");
    
    $stmt->execute([
        $latitud,
        $longitud,
        $latitud,
        $tipoVehiculo,
        $radioKm
    ]);
    
    $conductores = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'total' => count($conductores),
        'conductores' => $conductores
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
