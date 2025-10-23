<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Accept');

require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();

    $conductor_id = isset($_GET['conductor_id']) ? intval($_GET['conductor_id']) : 0;
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 20;
    $offset = ($page - 1) * $limit;

    if ($conductor_id <= 0) {
        throw new Exception('ID de conductor inválido');
    }

    // Contar total de viajes
    $query_count = "SELECT COUNT(*) as total
                    FROM solicitudes_servicio
                    WHERE conductor_id = :conductor_id
                    AND estado = 'completada'";
    
    $stmt_count = $db->prepare($query_count);
    $stmt_count->bindParam(':conductor_id', $conductor_id, PDO::PARAM_INT);
    $stmt_count->execute();
    $total = $stmt_count->fetch(PDO::FETCH_ASSOC)['total'];

    // Obtener historial de viajes
    $query = "SELECT 
                s.id,
                s.tipo_servicio,
                s.estado,
                s.precio_estimado,
                s.precio_final,
                s.distancia_km,
                s.duracion_estimada,
                s.fecha_solicitud,
                s.fecha_completado,
                uo.direccion as origen,
                ud.direccion as destino,
                u.nombre as cliente_nombre,
                u.apellido as cliente_apellido,
                c.calificacion,
                c.comentario
              FROM solicitudes_servicio s
              INNER JOIN usuarios u ON s.usuario_id = u.id
              LEFT JOIN ubicaciones_usuario uo ON s.ubicacion_origen_id = uo.id
              LEFT JOIN ubicaciones_usuario ud ON s.ubicacion_destino_id = ud.id
              LEFT JOIN calificaciones c ON s.id = c.solicitud_id
              WHERE s.conductor_id = :conductor_id
              AND s.estado = 'completada'
              ORDER BY s.fecha_completado DESC
              LIMIT :limit OFFSET :offset";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':conductor_id', $conductor_id, PDO::PARAM_INT);
    $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $viajes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'viajes' => $viajes,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => intval($total),
            'total_pages' => ceil($total / $limit)
        ],
        'message' => 'Historial obtenido exitosamente'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'viajes' => []
    ]);
}
?>
