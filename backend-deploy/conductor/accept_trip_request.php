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
    if (!isset($data['solicitud_id']) || !isset($data['conductor_id'])) {
        throw new Exception('Datos requeridos: solicitud_id, conductor_id');
    }
    
    $solicitudId = $data['solicitud_id'];
    $conductorId = $data['conductor_id'];
    
    $database = new Database();
    $db = $database->getConnection();
    $db->beginTransaction();
    
    try {
        // Verificar que la solicitud existe y está pendiente
        $stmt = $db->prepare("
            SELECT id, estado, usuario_id, tipo_vehiculo 
            FROM solicitudes_servicio 
            WHERE id = ? 
            FOR UPDATE
        ");
        $stmt->execute([$solicitudId]);
        $solicitud = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$solicitud) {
            throw new Exception('Solicitud no encontrada');
        }
        
        if ($solicitud['estado'] !== 'pendiente') {
            throw new Exception('La solicitud ya fue aceptada por otro conductor');
        }
        
        // Verificar que el conductor esté disponible
        $stmt = $db->prepare("
            SELECT u.id, dc.disponible, dc.vehiculo_tipo
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
        
        if (!$conductor['disponible']) {
            throw new Exception('Conductor no disponible');
        }
        
        if ($conductor['vehiculo_tipo'] !== $solicitud['tipo_vehiculo']) {
            throw new Exception('Tipo de vehículo no coincide');
        }
        
        // Actualizar la solicitud
        $stmt = $db->prepare("
            UPDATE solicitudes_servicio 
            SET estado = 'aceptada',
                fecha_actualizacion = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$solicitudId]);
        
        // Crear asignación
        $stmt = $db->prepare("
            INSERT INTO asignaciones_conductor (
                solicitud_id, 
                conductor_id, 
                fecha_asignacion, 
                estado
            ) VALUES (?, ?, NOW(), 'asignado')
        ");
        $stmt->execute([$solicitudId, $conductorId]);
        
        // Actualizar disponibilidad del conductor
        $stmt = $db->prepare("
            UPDATE detalles_conductor 
            SET disponible = 0 
            WHERE usuario_id = ?
        ");
        $stmt->execute([$conductorId]);
        
        $db->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Viaje aceptado exitosamente',
            'solicitud_id' => $solicitudId
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
