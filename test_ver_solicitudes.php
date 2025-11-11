<?php
/**
 * Script para ver todas las solicitudes en la base de datos
 * Muestra información detallada de cada solicitud
 */

require_once 'backend/config/database.php';

echo "==========================================================\n";
echo "👀 VER SOLICITUDES EN LA BASE DE DATOS\n";
echo "==========================================================\n\n";

$database = new Database();
$db = $database->getConnection();

try {
    // ==========================================
    // PASO 1: Estadísticas generales
    // ==========================================
    echo "📊 ESTADÍSTICAS GENERALES\n";
    echo "------------------------\n";

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

    echo "📈 Total de solicitudes: {$stats['total']}\n";
    echo "⏳ Pendientes: {$stats['pendientes']}\n";
    echo "🔍 En búsqueda: {$stats['en_busqueda']}\n";
    echo "✅ Aceptadas: {$stats['aceptadas']}\n";
    echo "❌ Rechazadas: {$stats['rechazadas']}\n";
    echo "🎯 Completadas: {$stats['completadas']}\n";
    echo "🚫 Canceladas: {$stats['canceladas']}\n";
    echo "⏰ Expiradas: {$stats['expiradas']}\n\n";

    if ($stats['total'] == 0) {
        echo "📭 No hay solicitudes en la base de datos\n";
        echo "💡 Usa 'php test_crear_solicitud.php' para crear solicitudes de prueba\n";
        exit(0);
    }

    // ==========================================
    // PASO 2: Menú de filtros
    // ==========================================
    echo "🔍 FILTRAR SOLICITUDES\n";
    echo "---------------------\n";
    echo "   [1] Ver TODAS las solicitudes\n";
    echo "   [2] Ver solo PENDIENTES\n";
    echo "   [3] Ver solo ACEPTADAS\n";
    echo "   [4] Ver solo COMPLETADAS\n";
    echo "   [5] Ver por ESTADO específico\n";
    echo "   [6] Ver por CLIENTE específico\n";
    echo "   [7] Ver ÚLTIMAS 10 solicitudes\n";
    echo "   [8] Ver solicitudes de HOY\n";
    echo "   [9] SALIR\n\n";

    echo "   Elige una opción (1-9): ";
    $opcion = trim(fgets(STDIN));

    if ($opcion == '9' || $opcion == '') {
        echo "\n👋 Hasta luego!\n";
        exit(0);
    }

    $query = "";
    $params = [];
    $titulo = "";

    switch ($opcion) {
        case '1':
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                ORDER BY s.fecha_creacion DESC
            ";
            $titulo = "TODAS LAS SOLICITUDES";
            break;

        case '2':
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                WHERE s.estado = 'pendiente'
                ORDER BY s.fecha_creacion DESC
            ";
            $titulo = "SOLICITUDES PENDIENTES";
            break;

        case '3':
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                WHERE s.estado = 'aceptada'
                ORDER BY s.fecha_creacion DESC
            ";
            $titulo = "SOLICITUDES ACEPTADAS";
            break;

        case '4':
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                WHERE s.estado = 'completada'
                ORDER BY s.fecha_creacion DESC
            ";
            $titulo = "SOLICITUDES COMPLETADAS";
            break;

        case '5':
            echo "   Estados disponibles: pendiente, aceptada, rechazada, completada, cancelada, en_busqueda, expirada\n";
            echo "   Ingresa el estado: ";
            $estado = trim(fgets(STDIN));
            if (empty($estado)) {
                echo "\n❌ Estado no válido\n";
                exit(1);
            }
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                WHERE s.estado = ?
                ORDER BY s.fecha_creacion DESC
            ";
            $params = [$estado];
            $titulo = "SOLICITUDES CON ESTADO '$estado'";
            break;

        case '6':
            echo "   Ingresa el ID del cliente: ";
            $clienteId = trim(fgets(STDIN));
            if (!is_numeric($clienteId)) {
                echo "\n❌ ID de cliente no válido\n";
                exit(1);
            }
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                WHERE s.cliente_id = ?
                ORDER BY s.fecha_creacion DESC
            ";
            $params = [$clienteId];
            $titulo = "SOLICITUDES DEL CLIENTE ID $clienteId";
            break;

        case '7':
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                ORDER BY s.fecha_creacion DESC
                LIMIT 10
            ";
            $titulo = "ÚLTIMAS 10 SOLICITUDES";
            break;

        case '8':
            $query = "
                SELECT
                    s.*,
                    u.nombre as cliente_nombre,
                    u.apellido as cliente_apellido,
                    u.email as cliente_email,
                    u.telefono as cliente_telefono,
                    TIMESTAMPDIFF(MINUTE, s.fecha_creacion, NOW()) as minutos_antiguedad
                FROM solicitudes_servicio s
                LEFT JOIN usuarios u ON s.cliente_id = u.id
                WHERE DATE(s.fecha_creacion) = CURDATE()
                ORDER BY s.fecha_creacion DESC
            ";
            $titulo = "SOLICITUDES DE HOY";
            break;

        default:
            echo "\n❌ Opción no válida\n";
            exit(1);
    }

    // ==========================================
    // PASO 3: Ejecutar consulta y mostrar resultados
    // ==========================================
    $stmt = $db->prepare($query);
    $stmt->execute($params);
    $solicitudes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "\n==========================================================\n";
    echo "📋 $titulo\n";
    echo "==========================================================\n";

    if (empty($solicitudes)) {
        echo "📭 No se encontraron solicitudes con los criterios especificados\n";
        exit(0);
    }

    echo "📊 Total encontrado: " . count($solicitudes) . " solicitudes\n\n";

    foreach ($solicitudes as $index => $sol) {
        $numero = $index + 1;

        // Determinar emoji según estado
        $emojiEstado = match($sol['estado']) {
            'pendiente' => '⏳',
            'aceptada' => '✅',
            'rechazada' => '❌',
            'completada' => '🎯',
            'cancelada' => '🚫',
            'en_busqueda' => '🔍',
            'expirada' => '⏰',
            default => '❓'
        };

        echo "╔══════════════════════════════════════════════════════════════╗\n";
        echo "║                    SOLICITUD #$numero                          ║\n";
        echo "╠══════════════════════════════════════════════════════════════╣\n";
        echo "║ 🆔 ID:              {$sol['id']}                                      ║\n";
        echo "║ 🔑 UUID:            " . substr($sol['uuid_solicitud'], 0, 36) . " ║\n";
        echo "║ 📊 Estado:          $emojiEstado " . strtoupper($sol['estado']) . str_repeat(' ', max(0, 25 - strlen($sol['estado']))) . " ║\n";
        echo "║ 👤 Cliente:         {$sol['cliente_nombre']} {$sol['cliente_apellido']}" . str_repeat(' ', max(0, 25 - strlen($sol['cliente_nombre'] . $sol['cliente_apellido']))) . " ║\n";
        echo "║ 📧 Email:           " . substr($sol['cliente_email'] ?? 'Sin email', 0, 35) . str_repeat(' ', max(0, 35 - strlen($sol['cliente_email'] ?? 'Sin email'))) . " ║\n";
        echo "║ 📞 Teléfono:        " . substr($sol['cliente_telefono'] ?? 'Sin teléfono', 0, 30) . str_repeat(' ', max(0, 30 - strlen($sol['cliente_telefono'] ?? 'Sin teléfono'))) . " ║\n";
        echo "║ 📅 Creada:          {$sol['fecha_creacion']}     ║\n";
        echo "║ ⏱️  Antigüedad:     {$sol['minutos_antiguedad']} minutos" . str_repeat(' ', max(0, 20 - strlen((string)$sol['minutos_antiguedad']))) . " ║\n";
        echo "║ 📍 Origen:          Lat: " . number_format($sol['latitud_recogida'], 4) . ", Lng: " . number_format($sol['longitud_recogida'], 4) . " ║\n";
        echo "║ 🏠 Dirección origen: " . substr($sol['direccion_recogida'] ?? 'Sin dirección', 0, 25) . str_repeat(' ', max(0, 25 - strlen($sol['direccion_recogida'] ?? 'Sin dirección'))) . " ║\n";
        echo "║ 📍 Destino:         Lat: " . number_format($sol['latitud_destino'], 4) . ", Lng: " . number_format($sol['longitud_destino'], 4) . " ║\n";
        echo "║ 🏢 Dirección destino: " . substr($sol['direccion_destino'] ?? 'Sin dirección', 0, 23) . str_repeat(' ', max(0, 23 - strlen($sol['direccion_destino'] ?? 'Sin dirección'))) . " ║\n";
        echo "║ 📏 Distancia:       {$sol['distancia_estimada']} km" . str_repeat(' ', max(0, 25 - strlen((string)$sol['distancia_estimada']))) . " ║\n";
        echo "║ ⏱️  Tiempo:         {$sol['tiempo_estimado']} minutos" . str_repeat(' ', max(0, 20 - strlen((string)$sol['tiempo_estimado']))) . " ║\n";

        if (isset($sol['conductor_asignado_id']) && $sol['conductor_asignado_id']) {
            echo "║ 🚗 Conductor ID:    {$sol['conductor_asignado_id']}" . str_repeat(' ', max(0, 25 - strlen((string)$sol['conductor_asignado_id']))) . " ║\n";
        }

        if (isset($sol['precio_final']) && $sol['precio_final']) {
            echo "║ 💰 Precio final:    \${$sol['precio_final']}" . str_repeat(' ', max(0, 25 - strlen((string)$sol['precio_final']))) . " ║\n";
        }

        if (isset($sol['fecha_aceptacion']) && $sol['fecha_aceptacion']) {
            echo "║ ✅ Aceptada:        {$sol['fecha_aceptacion']}     ║\n";
        }

        if (isset($sol['fecha_completada']) && $sol['fecha_completada']) {
            echo "║ 🎯 Completada:      {$sol['fecha_completada']}     ║\n";
        }

        echo "╚══════════════════════════════════════════════════════════════╝\n\n";
    }

    // ==========================================
    // RESUMEN FINAL
    // ==========================================
    echo "==========================================================\n";
    echo "✅ CONSULTA COMPLETADA\n";
    echo "==========================================================\n";
    echo "📊 Total mostrado: " . count($solicitudes) . " solicitudes\n";
    echo "🔍 Filtro aplicado: $titulo\n";
    echo "==========================================================\n";

} catch (Exception $e) {
    echo "\n❌ ERROR: " . $e->getMessage() . "\n";
    echo "📍 En: " . $e->getFile() . " línea " . $e->getLine() . "\n";
    echo "\n🔍 Stack trace:\n";
    echo $e->getTraceAsString() . "\n";
}
