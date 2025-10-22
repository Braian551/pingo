<?php
/**
 * Dashboard Stats API
 * Retorna estadísticas generales del sistema para el panel de administrador
 */

require_once '../config/config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Verificar que sea un administrador
    $input = $_SERVER['REQUEST_METHOD'] === 'GET' ? $_GET : getJsonInput();
    
    if (empty($input['admin_id'])) {
        sendJsonResponse(false, 'ID de administrador requerido');
    }

    $database = new Database();
    $db = $database->getConnection();

    // Verificar que el usuario sea administrador
    $checkAdmin = "SELECT tipo_usuario FROM usuarios WHERE id = ? AND tipo_usuario = 'administrador'";
    $stmtCheck = $db->prepare($checkAdmin);
    $stmtCheck->execute([$input['admin_id']]);
    
    if (!$stmtCheck->fetch()) {
        sendJsonResponse(false, 'Acceso denegado. Solo administradores pueden acceder.');
    }

    // === ESTADÍSTICAS GENERALES ===
    
    // Contar usuarios por tipo
    $queryUsers = "SELECT 
        COUNT(*) as total_usuarios,
        SUM(CASE WHEN tipo_usuario = 'cliente' THEN 1 ELSE 0 END) as total_clientes,
        SUM(CASE WHEN tipo_usuario = 'conductor' THEN 1 ELSE 0 END) as total_conductores,
        SUM(CASE WHEN tipo_usuario = 'administrador' THEN 1 ELSE 0 END) as total_administradores,
        SUM(CASE WHEN es_activo = 1 THEN 1 ELSE 0 END) as usuarios_activos,
        SUM(CASE WHEN DATE(fecha_registro) = CURDATE() THEN 1 ELSE 0 END) as registros_hoy
    FROM usuarios";
    
    $stmtUsers = $db->query($queryUsers);
    $userStats = $stmtUsers->fetch(PDO::FETCH_ASSOC);

    // Estadísticas de solicitudes
    $querySolicitudes = "SELECT 
        COUNT(*) as total_solicitudes,
        SUM(CASE WHEN estado = 'completado' THEN 1 ELSE 0 END) as completadas,
        SUM(CASE WHEN estado = 'cancelado' THEN 1 ELSE 0 END) as canceladas,
        SUM(CASE WHEN estado = 'en_proceso' THEN 1 ELSE 0 END) as en_proceso,
        SUM(CASE WHEN DATE(fecha_creacion) = CURDATE() THEN 1 ELSE 0 END) as solicitudes_hoy
    FROM solicitudes_servicio";
    
    $stmtSolicitudes = $db->query($querySolicitudes);
    $solicitudStats = $stmtSolicitudes->fetch(PDO::FETCH_ASSOC);

    // Ingresos (de tabla transacciones si existe)
    $queryIngresos = "SELECT 
        COALESCE(SUM(CASE WHEN estado = 'completado' THEN monto_total ELSE 0 END), 0) as ingresos_totales,
        COALESCE(SUM(CASE WHEN estado = 'completado' AND DATE(fecha_creacion) = CURDATE() THEN monto_total ELSE 0 END), 0) as ingresos_hoy
    FROM transacciones";
    
    try {
        $stmtIngresos = $db->query($queryIngresos);
        $ingresosStats = $stmtIngresos->fetch(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        // Si la tabla transacciones no existe aún
        $ingresosStats = ['ingresos_totales' => 0, 'ingresos_hoy' => 0];
    }

    // Reportes pendientes
    $queryReportes = "SELECT COUNT(*) as reportes_pendientes 
                      FROM reportes_usuarios 
                      WHERE estado = 'pendiente'";
    
    try {
        $stmtReportes = $db->query($queryReportes);
        $reportesStats = $stmtReportes->fetch(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        $reportesStats = ['reportes_pendientes' => 0];
    }

    // Últimas actividades (logs de auditoría)
    $queryActividades = "SELECT 
        l.id,
        l.accion,
        l.descripcion,
        l.fecha_creacion,
        u.nombre,
        u.apellido,
        u.email
    FROM logs_auditoria l
    LEFT JOIN usuarios u ON l.usuario_id = u.id
    ORDER BY l.fecha_creacion DESC
    LIMIT 10";
    
    try {
        $stmtActividades = $db->query($queryActividades);
        $actividades = $stmtActividades->fetchAll(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        $actividades = [];
    }

    // Grafica de registros últimos 7 días
    $queryRegistrosGrafica = "SELECT 
        DATE(fecha_registro) as fecha,
        COUNT(*) as cantidad
    FROM usuarios
    WHERE fecha_registro >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY DATE(fecha_registro)
    ORDER BY fecha ASC";
    
    $stmtGrafica = $db->query($queryRegistrosGrafica);
    $registrosGrafica = $stmtGrafica->fetchAll(PDO::FETCH_ASSOC);

    // Consolidar respuesta
    $dashboardData = [
        'usuarios' => $userStats,
        'solicitudes' => $solicitudStats,
        'ingresos' => $ingresosStats,
        'reportes' => $reportesStats,
        'actividades_recientes' => $actividades,
        'registros_ultimos_7_dias' => $registrosGrafica,
        'fecha_actualizacion' => date('Y-m-d H:i:s')
    ];

    sendJsonResponse(true, 'Estadísticas obtenidas exitosamente', $dashboardData);

} catch (Exception $e) {
    error_log("Error en dashboard_stats: " . $e->getMessage());
    http_response_code(500);
    sendJsonResponse(false, 'Error al obtener estadísticas: ' . $e->getMessage());
}
