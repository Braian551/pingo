<?php
// Test de conexión y creación de solicitud
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== Test de Backend - Crear Solicitud de Viaje ===\n\n";

// Incluir configuración de base de datos
require_once 'pingo/backend/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    echo "✓ Conexión a base de datos exitosa\n\n";
    
    // Datos de prueba
    $data = [
        'usuario_id' => 1,
        'latitud_origen' => 4.6097,
        'longitud_origen' => -74.0817,
        'direccion_origen' => 'Calle 123, Bogotá',
        'latitud_destino' => 4.6533,
        'longitud_destino' => -74.0836,
        'direccion_destino' => 'Carrera 45, Chapinero',
        'tipo_servicio' => 'viaje',
        'tipo_vehiculo' => 'moto',
        'distancia_km' => 5.5,
        'duracion_minutos' => 15,
        'precio_estimado' => 15000
    ];
    
    echo "Datos de prueba:\n";
    print_r($data);
    echo "\n";
    
    // Verificar usuario
    $stmt = $db->prepare("SELECT id, nombre FROM usuarios WHERE id = ? AND tipo_usuario = 'cliente'");
    $stmt->execute([$data['usuario_id']]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$usuario) {
        echo "✗ Usuario no encontrado\n";
        echo "Creando usuario de prueba...\n";
        
        // Crear usuario de prueba
        $stmt = $db->prepare("
            INSERT INTO usuarios (nombre, apellido, correo, telefono, tipo_usuario, es_activo)
            VALUES ('Usuario', 'Prueba', 'test@example.com', '3001234567', 'cliente', 1)
        ");
        $stmt->execute();
        $data['usuario_id'] = $db->lastInsertId();
        echo "✓ Usuario creado con ID: {$data['usuario_id']}\n";
    } else {
        echo "✓ Usuario encontrado: {$usuario['nombre']}\n";
    }
    
    // Mapear tipo_servicio
    $tipoServicioMap = [
        'viaje' => 'transporte',
        'paquete' => 'envio_paquete',
        'transporte' => 'transporte',
        'envio_paquete' => 'envio_paquete'
    ];
    $tipoServicio = $tipoServicioMap[$data['tipo_servicio']] ?? 'transporte';
    
    // Generar UUID
    $uuid = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
    
    // Crear solicitud
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
    echo "\n✓ Solicitud creada exitosamente con ID: $solicitudId\n";
    echo "UUID: $uuid\n\n";
    
    // Buscar conductores cercanos
    $vehiculoTipoMap = [
        'moto' => 'motocicleta',
        'carro' => 'carro',
        'moto_carga' => 'motocicleta',
        'carro_carga' => 'furgoneta'
    ];
    $vehiculoTipo = $vehiculoTipoMap[$data['tipo_vehiculo']] ?? 'motocicleta';
    $radiusKm = 5.0;
    
    $stmt = $db->prepare("
        SELECT 
            u.id,
            u.nombre,
            u.apellido,
            dc.vehiculo_tipo,
            dc.vehiculo_placa,
            dc.calificacion_promedio,
            dc.disponible,
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
    
    $conductores = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Conductores encontrados: " . count($conductores) . "\n";
    if (count($conductores) > 0) {
        echo "\nConductores disponibles:\n";
        foreach ($conductores as $conductor) {
            echo "  - {$conductor['nombre']} {$conductor['apellido']} ({$conductor['vehiculo_tipo']}) - {$conductor['distancia']}km\n";
        }
    }
    
    echo "\n=== Test completado exitosamente ===\n";
    
} catch (Exception $e) {
    echo "\n✗ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}
