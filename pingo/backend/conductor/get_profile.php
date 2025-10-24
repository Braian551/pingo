<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();

    $conductor_id = isset($_GET['conductor_id']) ? intval($_GET['conductor_id']) : 0;

    if ($conductor_id <= 0) {
        throw new Exception('ID de conductor inválido');
    }

    // Obtener información completa del conductor
    $query = "SELECT 
                u.id,
                u.nombre,
                u.apellido,
                u.email,
                u.telefono,
                u.foto_perfil,
                dc.licencia_conduccion,
                dc.licencia_vencimiento,
                dc.vehiculo_tipo,
                dc.vehiculo_marca,
                dc.vehiculo_modelo,
                dc.vehiculo_anio,
                dc.vehiculo_color,
                dc.vehiculo_placa,
                dc.aseguradora,
                dc.numero_poliza_seguro,
                dc.vencimiento_seguro,
                dc.calificacion_promedio,
                dc.total_viajes,
                dc.disponible,
                dc.estado_verificacion,
                dc.fecha_ultima_verificacion
              FROM usuarios u
              LEFT JOIN detalles_conductor dc ON u.id = dc.usuario_id
              WHERE u.id = :conductor_id AND u.tipo_usuario = 'conductor'";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':conductor_id', $conductor_id, PDO::PARAM_INT);
    $stmt->execute();

    $conductor = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$conductor) {
        throw new Exception('Conductor no encontrado');
    }

    // Build profile response
    $profile = [
        'conductor_id' => (int)$conductor['id'],
        'nombre_completo' => trim($conductor['nombre'] . ' ' . $conductor['apellido']),
        'email' => $conductor['email'],
        'telefono' => $conductor['telefono'],
        'foto_perfil' => $conductor['foto_perfil'],
        'calificacion_promedio' => (float)($conductor['calificacion_promedio'] ?? 0.0),
        'total_viajes' => (int)($conductor['total_viajes'] ?? 0),
        'disponible' => (bool)($conductor['disponible'] ?? false),
        'estado_verificacion' => $conductor['estado_verificacion'] ?? 'pendiente',
        'fecha_ultima_verificacion' => $conductor['fecha_ultima_verificacion'],
        
        // License information
        'licencia' => null,
        
        // Vehicle information
        'vehiculo' => null,
        
        // Profile completion status
        'is_profile_complete' => false,
        'completion_percentage' => 0.0,
        'pending_tasks' => [],
        'documentos_pendientes' => []
    ];

    // Build license info if exists
    if (!empty($conductor['licencia_conduccion'])) {
        $profile['licencia'] = [
            'numero_licencia' => $conductor['licencia_conduccion'],
            'fecha_emision' => null, // Not in current DB structure
            'fecha_vencimiento' => $conductor['licencia_vencimiento'],
            'categoria' => null, // Not in current DB structure
            'estado' => 'activa',
            'foto_frontal' => null, // Not in current DB structure
            'foto_trasera' => null // Not in current DB structure
        ];
    } else {
        $profile['pending_tasks'][] = 'Registrar licencia de conducción';
        $profile['documentos_pendientes'][] = 'licencia_conduccion';
    }

    // Build vehicle info if exists
    if (!empty($conductor['vehiculo_placa'])) {
        $profile['vehiculo'] = [
            'placa' => $conductor['vehiculo_placa'],
            'tipo' => $conductor['vehiculo_tipo'],
            'marca' => $conductor['vehiculo_marca'],
            'modelo' => $conductor['vehiculo_modelo'],
            'anio' => (int)$conductor['vehiculo_anio'],
            'color' => $conductor['vehiculo_color'],
            'aseguradora' => $conductor['aseguradora'],
            'numero_poliza' => $conductor['numero_poliza_seguro'],
            'vencimiento_seguro' => $conductor['vencimiento_seguro'],
            'foto_frontal' => null, // Not in current DB structure
            'foto_lateral' => null, // Not in current DB structure
            'tarjeta_propiedad' => null // Not in current DB structure
        ];
    } else {
        $profile['pending_tasks'][] = 'Registrar vehículo';
        $profile['documentos_pendientes'][] = 'vehiculo';
    }

    // Add other missing items
    if (empty($conductor['foto_perfil'])) {
        $profile['pending_tasks'][] = 'Subir foto de perfil';
        $profile['documentos_pendientes'][] = 'foto_perfil';
    }

    if (empty($conductor['aseguradora']) || empty($conductor['numero_poliza_seguro'])) {
        $profile['pending_tasks'][] = 'Registrar información del seguro';
        $profile['documentos_pendientes'][] = 'seguro';
    }

    // Calculate completion percentage
    $total_items = 4; // license, vehicle, photo, insurance
    $completed_items = 0;
    
    if (!empty($conductor['licencia_conduccion'])) $completed_items++;
    if (!empty($conductor['vehiculo_placa'])) $completed_items++;
    if (!empty($conductor['foto_perfil'])) $completed_items++;
    if (!empty($conductor['aseguradora'])) $completed_items++;
    
    $profile['completion_percentage'] = round($completed_items / $total_items, 2);
    $profile['is_profile_complete'] = count($profile['pending_tasks']) === 0;

    echo json_encode([
        'success' => true,
        'profile' => $profile,
        'message' => 'Perfil del conductor obtenido exitosamente'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
