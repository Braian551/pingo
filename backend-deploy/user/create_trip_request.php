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
    $required = ['usuario_id', 'latitud_origen', 'longitud_origen', 'direccion_origen', 
                 'latitud_destino', 'longitud_destino', 'direccion_destino', 
                 'tipo_servicio', 'distancia_km', 'duracion_minutos'];
    
    foreach ($required as $field) {
        if (!isset($data[$field])) {
            throw new Exception("Campo requerido faltante: $field");
        }
    }
    
    $database = new Database();
    $db = $database->getConnection();
    
    // Verificar que el usuario existe
    $stmt = $db->prepare("SELECT id, nombre FROM usuarios WHERE id = ? AND tipo_usuario = 'cliente'");
    $stmt->execute([$data['usuario_id']]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$usuario) {
        throw new Exception('Usuario no encontrado');
    }
    
    // Mapear tipo_servicio
    $tipoServicioMap = [
        'viaje' => 'transporte',
        'paquete' => 'envio_paquete',
        'transporte' => 'transporte',
        'envio_paquete' => 'envio_paquete'
    ];
    $tipoServicio = $tipoServicioMap[$data['tipo_servicio']] ?? 'transporte';
    
    // Generar UUID único
    $uuid = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
    
    // Crear la solicitud de servicio con los campos correctos de la tabla
    $stmt = $db->prepare("
        INSERT INTO solicitudes_servicio (
            uuid_solicitud,
            cliente_id, 
            tipo_servicio,
            latitud_recogida, 
            longitud_recogida, 
            direccion_recogida,
            latitud_destino, 
            longitud_destino, 
            direccion_destino,
            distancia_estimada,
            tiempo_estimado,
            estado,
            fecha_creacion,
            solicitado_en
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendiente', NOW(), NOW())
    ");
    
    $stmt->execute([
        $uuid,
        $data['usuario_id'],
        $tipoServicio,
        $data['latitud_origen'],
        $data['longitud_origen'],
        $data['direccion_origen'],
        $data['latitud_destino'],
        $data['longitud_destino'],
        $data['direccion_destino'],
        $data['distancia_km'],
        $data['duracion_minutos']
    ]);
    
    $solicitudId = $db->lastInsertId();
    
    // Buscar conductores cercanos disponibles (si se proporciona tipo_vehiculo)
    $conductoresCercanos = [];
    if (isset($data['tipo_vehiculo'])) {
        $radiusKm = 5.0; // Radio de búsqueda en kilómetros
        
        // Mapear tipo de vehículo de la app a la BD
        $vehiculoTipoMap = [
            'moto' => 'motocicleta',
            'carro' => 'carro',
            'moto_carga' => 'motocicleta', // Asumiendo que moto_carga también usa motocicleta
            'carro_carga' => 'furgoneta'
        ];
        $vehiculoTipo = $vehiculoTipoMap[$data['tipo_vehiculo']] ?? 'motocicleta';
        
        $stmt = $db->prepare("
            SELECT 
                u.id,
                u.nombre,
                u.apellido,
                u.telefono,
                u.foto_perfil,
                dc.vehiculo_tipo,
                dc.vehiculo_marca,
                dc.vehiculo_modelo,
                dc.vehiculo_placa,
                dc.vehiculo_color,
                dc.calificacion_promedio,
                dc.latitud_actual,
                dc.longitud_actual,
                (6371 * acos(
                    cos(radians(?)) * cos(radians(dc.latitud_actual)) *
                    cos(radians(dc.longitud_actual) - radians(?)) +
                    sin(radians(?)) * sin(radians(dc.latitud_actual))
                )) AS distancia
            FROM usuarios u
            INNER JOIN detalles_conductor dc ON u.id = dc.usuario_id
            WHERE u.tipo_usuario = 'conductor'
            AND u.es_activo = 1
            AND dc.disponible = 1
            AND dc.estado_verificacion = 'aprobado'
            AND dc.vehiculo_tipo = ?
            AND dc.latitud_actual IS NOT NULL
            AND dc.longitud_actual IS NOT NULL
            HAVING distancia <= ?
            ORDER BY distancia ASC
            LIMIT 10
        ");
        
        $stmt->execute([
            $data['latitud_origen'],
            $data['longitud_origen'],
            $data['latitud_origen'],
            $vehiculoTipo,
            $radiusKm
        ]);
        
        $conductoresCercanos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Solicitud creada exitosamente',
        'solicitud_id' => $solicitudId,
        'conductores_encontrados' => count($conductoresCercanos),
        'conductores' => $conductoresCercanos
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
