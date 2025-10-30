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
    // Obtener el ID del conductor
    $conductorId = $_GET['conductor_id'] ?? null;
    
    if (!$conductorId) {
        throw new Exception('ID del conductor requerido');
    }
    
    $database = new Database();
    $db = $database->getConnection();
    
    // Verificar que sea un conductor válido y disponible
    $stmt = $db->prepare("
        SELECT u.id, u.disponibilidad, u.latitud_actual, u.longitud_actual, dc.tipo_vehiculo
        FROM usuarios u
        INNER JOIN detalles_conductor dc ON u.id = dc.usuario_id
        WHERE u.id = ? 
        AND u.tipo_usuario = 'conductor'
        AND dc.estado_verificacion = 'aprobado'
    ");
    $stmt->execute([$conductorId]);
    $conductor = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$conductor) {
        throw new Exception('Conductor no encontrado o no verificado');
    }
    
    if (!$conductor['disponibilidad']) {
        echo json_encode([
            'success' => true,
            'message' => 'Conductor no disponible',
            'solicitudes' => []
        ]);
        exit;
    }
    
    // Buscar solicitudes pendientes cercanas al conductor
    $radioKm = 5.0; // Radio de búsqueda
    
    $stmt = $db->prepare("
        SELECT 
            s.id,
            s.usuario_id,
            s.latitud_origen,
            s.longitud_origen,
            s.direccion_origen,
            s.latitud_destino,
            s.longitud_destino,
            s.direccion_destino,
            s.tipo_servicio,
            s.tipo_vehiculo,
            s.distancia_km,
            s.duracion_minutos,
            s.precio_estimado,
            s.estado,
            s.fecha_solicitud,
            u.nombre as nombre_usuario,
            u.telefono as telefono_usuario,
            u.foto_perfil as foto_usuario,
            (6371 * acos(
                cos(radians(?)) * cos(radians(s.latitud_origen)) *
                cos(radians(s.longitud_origen) - radians(?)) +
                sin(radians(?)) * sin(radians(s.latitud_origen))
            )) AS distancia_conductor_origen
        FROM solicitudes_servicio s
        INNER JOIN usuarios u ON s.usuario_id = u.id
        WHERE s.estado = 'pendiente'
        AND s.tipo_vehiculo = ?
        AND s.fecha_solicitud >= DATE_SUB(NOW(), INTERVAL 10 MINUTE)
        HAVING distancia_conductor_origen <= ?
        ORDER BY s.fecha_solicitud DESC
        LIMIT 10
    ");
    
    $stmt->execute([
        $conductor['latitud_actual'],
        $conductor['longitud_actual'],
        $conductor['latitud_actual'],
        $conductor['tipo_vehiculo'],
        $radioKm
    ]);
    
    $solicitudes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'total' => count($solicitudes),
        'solicitudes' => $solicitudes
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
