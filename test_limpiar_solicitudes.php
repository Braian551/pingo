<?php
/**
 * Script de prueba para limpiar/eliminar solicitudes de la base de datos
 * Permite eliminar solicitudes con diferentes criterios
 */

require_once 'backend/config/database.php';

echo "==========================================================\n";
echo "🧹 TEST: LIMPIAR SOLICITUDES DE LA BASE DE DATOS\n";
echo "==========================================================\n\n";

$database = new Database();
$db = $database->getConnection();

try {
    // ==========================================
    // PASO 1: Mostrar estadísticas actuales
    // ==========================================
    echo "📊 PASO 1: Estadísticas actuales de solicitudes...\n";

    $stmt = $db->prepare("
        SELECT
            COUNT(*) as total,
            SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) as pendientes,
            SUM(CASE WHEN estado = 'aceptada' THEN 1 ELSE 0 END) as aceptadas,
            SUM(CASE WHEN estado = 'rechazada' THEN 1 ELSE 0 END) as rechazadas,
            SUM(CASE WHEN estado = 'completada' THEN 1 ELSE 0 END) as completadas,
            SUM(CASE WHEN estado = 'cancelada' THEN 1 ELSE 0 END) as canceladas,
            SUM(CASE WHEN estado = 'en_busqueda' THEN 1 ELSE 0 END) as en_busqueda,
            SUM(CASE WHEN estado = 'expirada' THEN 1 ELSE 0 END) as expiradas
        FROM solicitudes_servicio
    ");
    $stmt->execute();
    $stats = $stmt->fetch(PDO::FETCH_ASSOC);

    echo "   📈 Total de solicitudes: {$stats['total']}\n";
    echo "   ⏳ Pendientes: {$stats['pendientes']}\n";
    echo "   🔍 En búsqueda: {$stats['en_busqueda']}\n";
    echo "   ✅ Aceptadas: {$stats['aceptadas']}\n";
    echo "   ❌ Rechazadas: {$stats['rechazadas']}\n";
    echo "   🎯 Completadas: {$stats['completadas']}\n";
    echo "   🚫 Canceladas: {$stats['canceladas']}\n";
    echo "   ⏰ Expiradas: {$stats['expiradas']}\n\n";

    // ==========================================
    // PASO 2: Mostrar solicitudes recientes
    // ==========================================
    echo "📝 PASO 2: Últimas 10 solicitudes...\n";

    $stmt = $db->prepare("
        SELECT
            s.id,
            s.uuid_solicitud,
            s.estado,
            s.fecha_creacion,
            s.direccion_recogida,
            u.nombre as cliente_nombre,
            u.telefono
        FROM solicitudes_servicio s
        LEFT JOIN usuarios u ON s.cliente_id = u.id
        ORDER BY s.fecha_creacion DESC
        LIMIT 10
    ");
    $stmt->execute();
    $solicitudes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($solicitudes)) {
        echo "   📭 No hay solicitudes en la base de datos\n\n";
    } else {
        echo "   ╔════╤══════════════════════╤════════════╤══════════════════════════════════════════════╗\n";
        echo "   ║ ID │ UUID                 │ Estado     │ Cliente / Dirección                       ║\n";
        echo "   ╠════╪══════════════════════╪════════════╪══════════════════════════════════════════════╣\n";

        foreach ($solicitudes as $sol) {
            $uuid = substr($sol['uuid_solicitud'], 0, 20) . "...";
            $estado = str_pad($sol['estado'], 10);
            $cliente = $sol['cliente_nombre'] ? substr($sol['cliente_nombre'], 0, 25) : 'Sin cliente';
            $cliente = str_pad($cliente, 25);

            echo "   ║ " . str_pad($sol['id'], 2) . " │ $uuid │ $estado │ $cliente ║\n";
        }
        echo "   ╚════╧══════════════════════╧════════════╧══════════════════════════════════════════════╝\n\n";
    }

    // ==========================================
    // PASO 3: Menú de opciones de limpieza
    // ==========================================
    echo "🧹 PASO 3: Selecciona el tipo de limpieza...\n";
    echo "   [1] Eliminar TODAS las solicitudes\n";
    echo "   [2] Eliminar solicitudes PENDIENTES\n";
    echo "   [3] Eliminar solicitudes ANTIGUAS (más de 1 hora)\n";
    echo "   [4] Eliminar solicitudes ANTIGUAS (más de 24 horas)\n";
    echo "   [5] Eliminar solicitudes por ESTADO específico\n";
    echo "   [6] Eliminar solicitudes por ID específico\n";
    echo "   [7] Eliminar solicitudes de un CLIENTE específico\n";
    echo "   [8] Limpiar solo solicitudes de PRUEBA (con 'Prueba' en dirección)\n";
    echo "   [9] CANCELAR (no eliminar nada)\n\n";

    echo "   Elige una opción (1-9): ";
    $opcion = trim(fgets(STDIN));

    if ($opcion == '9' || $opcion == '') {
        echo "\n❌ Operación cancelada por el usuario\n";
        exit(0);
    }

    $query = "";
    $params = [];
    $descripcion = "";

    switch ($opcion) {
        case '1':
            $query = "DELETE FROM solicitudes_servicio";
            $descripcion = "TODAS las solicitudes";
            break;

        case '2':
            $query = "DELETE FROM solicitudes_servicio WHERE estado = 'pendiente'";
            $descripcion = "solicitudes PENDIENTES";
            break;

        case '3':
            $query = "DELETE FROM solicitudes_servicio WHERE fecha_creacion < DATE_SUB(NOW(), INTERVAL 1 HOUR)";
            $descripcion = "solicitudes de más de 1 hora";
            break;

        case '4':
            $query = "DELETE FROM solicitudes_servicio WHERE fecha_creacion < DATE_SUB(NOW(), INTERVAL 24 HOUR)";
            $descripcion = "solicitudes de más de 24 horas";
            break;

        case '5':
            echo "   Estados disponibles: pendiente, aceptada, rechazada, completada, cancelada, en_busqueda, expirada\n";
            echo "   Ingresa el estado: ";
            $estado = trim(fgets(STDIN));
            if (empty($estado)) {
                echo "\n❌ Estado no válido\n";
                exit(1);
            }
            $query = "DELETE FROM solicitudes_servicio WHERE estado = ?";
            $params = [$estado];
            $descripcion = "solicitudes con estado '$estado'";
            break;

        case '6':
            echo "   Ingresa el ID de la solicitud: ";
            $id = trim(fgets(STDIN));
            if (!is_numeric($id)) {
                echo "\n❌ ID no válido\n";
                exit(1);
            }
            $query = "DELETE FROM solicitudes_servicio WHERE id = ?";
            $params = [$id];
            $descripcion = "solicitud con ID $id";
            break;

        case '7':
            echo "   Ingresa el ID del cliente: ";
            $clienteId = trim(fgets(STDIN));
            if (!is_numeric($clienteId)) {
                echo "\n❌ ID de cliente no válido\n";
                exit(1);
            }
            $query = "DELETE FROM solicitudes_servicio WHERE cliente_id = ?";
            $params = [$clienteId];
            $descripcion = "solicitudes del cliente ID $clienteId";
            break;

        case '8':
            $query = "DELETE FROM solicitudes_servicio WHERE direccion_recogida LIKE '%Prueba%' OR direccion_destino LIKE '%Prueba%'";
            $descripcion = "solicitudes de PRUEBA (con 'Prueba' en dirección)";
            break;

        default:
            echo "\n❌ Opción no válida\n";
            exit(1);
    }

    // ==========================================
    // PASO 4: Confirmación y ejecución
    // ==========================================
    echo "\n⚠️  CONFIRMACIÓN DE ELIMINACIÓN\n";
    echo "   Vas a eliminar: $descripcion\n";

    // Contar cuántas se van a eliminar
    $countQuery = str_replace('DELETE FROM', 'SELECT COUNT(*) as total FROM', $query);
    $stmt = $db->prepare($countQuery);
    $stmt->execute($params);
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    echo "   📊 Cantidad a eliminar: $count solicitudes\n";

    // Verificar dependencias (calificaciones)
    $dependenciasQuery = str_replace('DELETE FROM solicitudes_servicio', 'SELECT COUNT(*) as calificaciones FROM calificaciones WHERE solicitud_id IN (SELECT id FROM solicitudes_servicio', $query);
    if (strpos($dependenciasQuery, 'WHERE') !== false) {
        $dependenciasQuery .= ')';
    } else {
        $dependenciasQuery = str_replace('FROM calificaciones WHERE solicitud_id IN (SELECT id FROM solicitudes_servicio)', 'FROM calificaciones', $dependenciasQuery);
    }

    try {
        $stmt = $db->prepare($dependenciasQuery);
        $stmt->execute($params);
        $calificacionesCount = $stmt->fetch(PDO::FETCH_ASSOC)['calificaciones'] ?? 0;

        if ($calificacionesCount > 0) {
            echo "   ⚠️  ADVERTENCIA: También se eliminarán $calificacionesCount calificaciones asociadas\n";
            echo "   💡 Las calificaciones están vinculadas a estas solicitudes\n";
        }
    } catch (Exception $e) {
        // Ignorar errores en la consulta de dependencias
    }

    echo "\n";

    if ($count == 0) {
        echo "   ✅ No hay solicitudes que coincidan con los criterios\n";
        echo "   🔄 No se realizó ninguna eliminación\n";
        exit(0);
    }

    echo "   ⚠️  ¿Estás seguro? (escribe 'SI' para confirmar): ";
    $confirmacion = trim(fgets(STDIN));

    if (strtoupper($confirmacion) !== 'SI') {
        echo "\n❌ Operación cancelada\n";
        exit(0);
    }

    // Ejecutar eliminación
    echo "\n🗑️  Ejecutando eliminación...\n";

    // Si hay calificaciones relacionadas, eliminarlas primero
    if (isset($calificacionesCount) && $calificacionesCount > 0) {
        echo "   🗑️  Eliminando $calificacionesCount calificaciones relacionadas...\n";

        // Construir query para eliminar calificaciones
        $deleteCalificacionesQuery = str_replace('DELETE FROM solicitudes_servicio', 'DELETE FROM calificaciones WHERE solicitud_id IN (SELECT id FROM solicitudes_servicio', $query);
        if (strpos($deleteCalificacionesQuery, 'WHERE') !== false) {
            $deleteCalificacionesQuery .= ')';
        }

        try {
            $stmt = $db->prepare($deleteCalificacionesQuery);
            $stmt->execute($params);
            $calificacionesEliminadas = $stmt->rowCount();
            echo "   ✅ Calificaciones eliminadas: $calificacionesEliminadas\n";
        } catch (Exception $e) {
            echo "   ⚠️  Error al eliminar calificaciones: " . $e->getMessage() . "\n";
            echo "   🔄 Continuando con la eliminación de solicitudes...\n";
        }
    }

    // Ahora eliminar las solicitudes
    $stmt = $db->prepare($query);
    $stmt->execute($params);
    $eliminadas = $stmt->rowCount();

    echo "   ✅ ¡Eliminación completada!\n";
    echo "   📊 Solicitudes eliminadas: $eliminadas\n";
    if (isset($calificacionesEliminadas) && $calificacionesEliminadas > 0) {
        echo "   ⭐ Calificaciones eliminadas: $calificacionesEliminadas\n";
    }

    // ==========================================
    // PASO 5: Verificar resultado
    // ==========================================
    echo "\n📊 PASO 5: Verificando resultado...\n";

    $stmt = $db->prepare("
        SELECT
            COUNT(*) as total,
            SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) as pendientes,
            SUM(CASE WHEN estado = 'aceptada' THEN 1 ELSE 0 END) as aceptadas,
            SUM(CASE WHEN estado = 'rechazada' THEN 1 ELSE 0 END) as rechazadas,
            SUM(CASE WHEN estado = 'completada' THEN 1 ELSE 0 END) as completadas,
            SUM(CASE WHEN estado = 'cancelada' THEN 1 ELSE 0 END) as canceladas,
            SUM(CASE WHEN estado = 'en_busqueda' THEN 1 ELSE 0 END) as en_busqueda,
            SUM(CASE WHEN estado = 'expirada' THEN 1 ELSE 0 END) as expiradas
        FROM solicitudes_servicio
    ");
    $stmt->execute();
    $statsFinal = $stmt->fetch(PDO::FETCH_ASSOC);

    echo "   📈 Estadísticas después de la limpieza:\n";
    echo "      Total: {$statsFinal['total']} (antes: {$stats['total']})\n";
    echo "      Pendientes: {$statsFinal['pendientes']} (antes: {$stats['pendientes']})\n";
    echo "      En búsqueda: {$statsFinal['en_busqueda']} (antes: {$stats['en_busqueda']})\n";
    echo "      Aceptadas: {$statsFinal['aceptadas']} (antes: {$stats['aceptadas']})\n";
    echo "      Rechazadas: {$statsFinal['rechazadas']} (antes: {$stats['rechazadas']})\n";
    echo "      Completadas: {$statsFinal['completadas']} (antes: {$stats['completadas']})\n";
    echo "      Canceladas: {$statsFinal['canceladas']} (antes: {$stats['canceladas']})\n";
    echo "      Expiradas: {$statsFinal['expiradas']} (antes: {$stats['expiradas']})\n";

    // ==========================================
    // RESUMEN FINAL
    // ==========================================
    echo "\n==========================================================\n";
    echo "✅ LIMPIEZA COMPLETADA EXITOSAMENTE\n";
    echo "==========================================================\n";
    echo "📊 RESUMEN:\n";
    echo "   🗑️  Tipo de limpieza: $descripcion\n";
    echo "   📈 Solicitudes eliminadas: $eliminadas\n";
    if (isset($calificacionesEliminadas) && $calificacionesEliminadas > 0) {
        echo "   ⭐ Calificaciones eliminadas: $calificacionesEliminadas\n";
    }
    echo "   📊 Solicitudes restantes: {$statsFinal['total']}\n";
    echo "\n💡 NOTA: La base de datos ha sido limpiada según los criterios especificados.\n";
    echo "==========================================================\n";

} catch (Exception $e) {
    echo "\n❌ ERROR: " . $e->getMessage() . "\n";
    echo "📍 En: " . $e->getFile() . " línea " . $e->getLine() . "\n";
    echo "\n🔍 Stack trace:\n";
    echo $e->getTraceAsString() . "\n";
}
