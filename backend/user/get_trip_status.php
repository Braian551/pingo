<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';

try {
    $solicitudId = $_GET['solicitud_id'] ?? null;
    
    if (!$solicitudId) {
        throw new Exception('solicitud_id es requerido');
    }
    
    $database = new Database();
    $db = $database->getConnection();
    
    // Obtener información de la solicitud con datos del conductor asignado
    $stmt = $db->prepare("
        SELECT 
            s.*,
            ac.conductor_id,
            ac.estado as estado_asignacion,
            ac.fecha_asignacion,
            u.nombre as conductor_nombre,
            u.apellido as conductor_apellido,
            u.telefono as conductor_telefono,
            u.foto_perfil as conductor_foto,
            dc.vehiculo_tipo,
            dc.vehiculo_marca,
            dc.vehiculo_modelo,
            dc.vehiculo_placa,
            dc.vehiculo_color,
            dc.calificacion_promedio as conductor_calificacion,
            dc.latitud_actual as conductor_latitud,
            dc.longitud_actual as conductor_longitud,
            (6371 * acos(
                cos(radians(s.latitud_recogida)) * cos(radians(dc.latitud_actual)) *
                cos(radians(dc.longitud_actual) - radians(s.longitud_recogida)) +
                sin(radians(s.latitud_recogida)) * sin(radians(dc.latitud_actual))
            )) AS distancia_conductor_km
        FROM solicitudes_servicio s
        LEFT JOIN asignaciones_conductor ac ON s.id = ac.solicitud_id AND ac.estado = 'asignado'
        LEFT JOIN usuarios u ON ac.conductor_id = u.id
        LEFT JOIN detalles_conductor dc ON u.id = dc.usuario_id
        WHERE s.id = ?
    ");
    
    $stmt->execute([$solicitudId]);
    $trip = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$trip) {
        throw new Exception('Solicitud no encontrada');
    }
    
    // Calcular ETA si hay conductor asignado
    $eta_minutos = null;
    if ($trip['conductor_id'] && $trip['conductor_latitud'] && $trip['conductor_longitud']) {
        // Estimación simple: 30 km/h promedio en ciudad
        $distanciaKm = floatval($trip['distancia_conductor_km']);
        $eta_minutos = round(($distanciaKm / 30) * 60);
    }
    
    echo json_encode([
        'success' => true,
        'trip' => [
            'id' => (int)$trip['id'],
            'uuid' => $trip['uuid_solicitud'],
            'estado' => $trip['estado'],
            'tipo_servicio' => $trip['tipo_servicio'],
            'origen' => [
                'latitud' => (float)$trip['latitud_recogida'],
                'longitud' => (float)$trip['longitud_recogida'],
                'direccion' => $trip['direccion_recogida']
            ],
            'destino' => [
                'latitud' => (float)$trip['latitud_destino'],
                'longitud' => (float)$trip['longitud_destino'],
                'direccion' => $trip['direccion_destino']
            ],
            'distancia_km' => (float)$trip['distancia_estimada'],
            'tiempo_estimado_min' => (int)$trip['tiempo_estimado'],
            'fecha_creacion' => $trip['fecha_creacion'],
            'conductor' => $trip['conductor_id'] ? [
                'id' => (int)$trip['conductor_id'],
                'nombre' => $trip['conductor_nombre'] . ' ' . $trip['conductor_apellido'],
                'telefono' => $trip['conductor_telefono'],
                'foto' => $trip['conductor_foto'],
                'calificacion' => (float)$trip['conductor_calificacion'],
                'vehiculo' => [
                    'tipo' => $trip['vehiculo_tipo'],
                    'marca' => $trip['vehiculo_marca'],
                    'modelo' => $trip['vehiculo_modelo'],
                    'placa' => $trip['vehiculo_placa'],
                    'color' => $trip['vehiculo_color']
                ],
                'ubicacion' => [
                    'latitud' => (float)$trip['conductor_latitud'],
                    'longitud' => (float)$trip['conductor_longitud']
                ],
                'distancia_km' => round((float)$trip['distancia_conductor_km'], 2),
                'eta_minutos' => $eta_minutos
            ] : null
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
