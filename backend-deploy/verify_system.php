<?php
// Script de verificación del sistema de viajes
header('Content-Type: text/plain; charset=utf-8');

echo "═══════════════════════════════════════════════\n";
echo "   VERIFICACIÓN DEL SISTEMA DE VIAJES\n";
echo "═══════════════════════════════════════════════\n\n";

require_once __DIR__ . '/config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    echo "✓ Conexión a base de datos exitosa\n\n";
    
    // 1. Verificar usuarios
    echo "1. USUARIOS\n";
    echo "───────────────────────────────────────────────\n";
    $stmt = $db->query("SELECT COUNT(*) as total, tipo_usuario FROM usuarios GROUP BY tipo_usuario");
    $usuarios = $stmt->fetchAll();
    
    foreach ($usuarios as $row) {
        echo "   {$row['tipo_usuario']}: {$row['total']}\n";
    }
    echo "\n";
    
    // 2. Verificar conductores aprobados
    echo "2. CONDUCTORES APROBADOS\n";
    echo "───────────────────────────────────────────────\n";
    $stmt = $db->query("
        SELECT 
            u.id,
            u.nombre,
            u.disponibilidad,
            IFNULL(u.latitud_actual, 'Sin ubicación') as latitud,
            IFNULL(u.longitud_actual, 'Sin ubicación') as longitud,
            dc.tipo_vehiculo,
            dc.estado_verificacion
        FROM usuarios u
        INNER JOIN detalles_conductor dc ON u.id = dc.usuario_id
        WHERE u.tipo_usuario = 'conductor'
        AND dc.estado_verificacion = 'aprobado'
    ");
    $conductores = $stmt->fetchAll();
    
    if (count($conductores) > 0) {
        foreach ($conductores as $conductor) {
            $disponible = $conductor['disponibilidad'] ? '✓ Disponible' : '✗ No disponible';
            $ubicacion = $conductor['latitud'] === 'Sin ubicación' ? '⚠ Sin ubicación' : '✓ Con ubicación';
            echo "   ID: {$conductor['id']} | {$conductor['nombre']}\n";
            echo "      Vehículo: {$conductor['tipo_vehiculo']}\n";
            echo "      Estado: {$disponible} | {$ubicacion}\n";
            echo "      Coords: {$conductor['latitud']}, {$conductor['longitud']}\n\n";
        }
    } else {
        echo "   ⚠ No hay conductores aprobados\n\n";
    }
    
    // 3. Verificar solicitudes pendientes
    echo "3. SOLICITUDES PENDIENTES\n";
    echo "───────────────────────────────────────────────\n";
    $stmt = $db->query("
        SELECT 
            s.id,
            s.tipo_vehiculo,
            s.estado,
            s.precio_estimado,
            u.nombre as usuario,
            s.fecha_solicitud
        FROM solicitudes_servicio s
        INNER JOIN usuarios u ON s.usuario_id = u.id
        WHERE s.estado = 'pendiente'
        ORDER BY s.fecha_solicitud DESC
        LIMIT 5
    ");
    $solicitudes = $stmt->fetchAll();
    
    if (count($solicitudes) > 0) {
        foreach ($solicitudes as $sol) {
            echo "   ID: {$sol['id']} | Usuario: {$sol['usuario']}\n";
            echo "      Vehículo: {$sol['tipo_vehiculo']} | Precio: \${$sol['precio_estimado']}\n";
            echo "      Fecha: {$sol['fecha_solicitud']}\n\n";
        }
    } else {
        echo "   ℹ No hay solicitudes pendientes\n\n";
    }
    
    // 4. Verificar estructura de tablas
    echo "4. VERIFICACIÓN DE TABLAS\n";
    echo "───────────────────────────────────────────────\n";
    $tablas = [
        'usuarios',
        'detalles_conductor',
        'solicitudes_servicio',
        'asignaciones_conductor'
    ];
    
    foreach ($tablas as $tabla) {
        $stmt = $db->query("SHOW TABLES LIKE '$tabla'");
        $existe = $stmt->fetch();
        if ($existe) {
            $stmt = $db->query("SELECT COUNT(*) as total FROM $tabla");
            $count = $stmt->fetch();
            echo "   ✓ $tabla ({$count['total']} registros)\n";
        } else {
            echo "   ✗ $tabla NO EXISTE\n";
        }
    }
    echo "\n";
    
    // 5. Verificar campos necesarios en usuarios
    echo "5. CAMPOS EN TABLA USUARIOS\n";
    echo "───────────────────────────────────────────────\n";
    $campos = ['latitud_actual', 'longitud_actual', 'disponibilidad'];
    $stmt = $db->query("DESCRIBE usuarios");
    $columns = $stmt->fetchAll();
    $columnNames = array_column($columns, 'Field');
    
    foreach ($campos as $campo) {
        if (in_array($campo, $columnNames)) {
            echo "   ✓ $campo\n";
        } else {
            echo "   ✗ $campo FALTA\n";
        }
    }
    echo "\n";
    
    // 6. Recomendaciones
    echo "6. RECOMENDACIONES\n";
    echo "───────────────────────────────────────────────\n";
    
    $problemas = [];
    
    // Verificar conductores sin ubicación
    $stmt = $db->query("
        SELECT COUNT(*) as total 
        FROM usuarios 
        WHERE tipo_usuario = 'conductor' 
        AND (latitud_actual IS NULL OR longitud_actual IS NULL)
    ");
    $sinUbicacion = $stmt->fetch();
    if ($sinUbicacion['total'] > 0) {
        $problemas[] = "   ⚠ {$sinUbicacion['total']} conductor(es) sin ubicación actual";
    }
    
    // Verificar conductores sin aprobar
    $stmt = $db->query("
        SELECT COUNT(*) as total 
        FROM detalles_conductor 
        WHERE estado_verificacion != 'aprobado'
    ");
    $sinAprobar = $stmt->fetch();
    if ($sinAprobar['total'] > 0) {
        $problemas[] = "   ℹ {$sinAprobar['total']} conductor(es) pendiente(s) de aprobación";
    }
    
    // Verificar conductores disponibles
    $stmt = $db->query("
        SELECT COUNT(*) as total 
        FROM usuarios u
        INNER JOIN detalles_conductor dc ON u.id = dc.usuario_id
        WHERE u.tipo_usuario = 'conductor'
        AND u.disponibilidad = 1
        AND dc.estado_verificacion = 'aprobado'
        AND u.latitud_actual IS NOT NULL
        AND u.longitud_actual IS NOT NULL
    ");
    $disponibles = $stmt->fetch();
    
    if ($disponibles['total'] == 0) {
        $problemas[] = "   ⚠ NO HAY CONDUCTORES DISPONIBLES para recibir viajes";
        $problemas[] = "      Solución: Actualizar ubicación y disponibilidad de conductores";
    } else {
        echo "   ✓ {$disponibles['total']} conductor(es) listo(s) para recibir viajes\n";
    }
    
    if (count($problemas) > 0) {
        echo "\n   PROBLEMAS DETECTADOS:\n";
        foreach ($problemas as $problema) {
            echo "$problema\n";
        }
    }
    
    echo "\n";
    echo "═══════════════════════════════════════════════\n";
    echo "   VERIFICACIÓN COMPLETADA\n";
    echo "═══════════════════════════════════════════════\n\n";
    
    // 7. Comandos útiles
    echo "COMANDOS ÚTILES:\n";
    echo "───────────────────────────────────────────────\n";
    echo "Actualizar ubicación de conductor:\n";
    echo "UPDATE usuarios SET \n";
    echo "  latitud_actual = 6.2476,\n";
    echo "  longitud_actual = -75.5658,\n";
    echo "  disponibilidad = 1\n";
    echo "WHERE id = [ID_CONDUCTOR];\n\n";
    
    echo "Ver solicitudes recientes:\n";
    echo "SELECT * FROM solicitudes_servicio \n";
    echo "ORDER BY fecha_solicitud DESC LIMIT 5;\n\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
}
?>
