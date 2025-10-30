<?php
require_once '../config/config.php';

try {
    $input = getJsonInput();

    if (empty($input['email']) || empty($input['password'])) {
        sendJsonResponse(false, 'Email y password son requeridos');
    }

    $email = $input['email'];
    $password = $input['password'];

    $database = new Database();
    $db = $database->getConnection();

    $query = "SELECT id, uuid, nombre, apellido, email, telefono, tipo_usuario, hash_contrasena FROM usuarios WHERE email = ? LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        sendJsonResponse(false, 'Usuario no encontrado');
    }

    // Verificar contraseña
    if (!password_verify($password, $user['hash_contrasena'])) {
        sendJsonResponse(false, 'Contraseña incorrecta');
    }

    // No devolver hash
    unset($user['hash_contrasena']);

    // Registrar login en logs de auditoría
    try {
        $logQuery = "INSERT INTO logs_auditoria (usuario_id, accion, descripcion, ip_address, user_agent) 
                     VALUES (?, 'login', 'Usuario inició sesión exitosamente', ?, ?)";
        $logStmt = $db->prepare($logQuery);
        $logStmt->execute([
            $user['id'], 
            $_SERVER['REMOTE_ADDR'] ?? null,
            $_SERVER['HTTP_USER_AGENT'] ?? null
        ]);
    } catch (Exception $e) {
        // No detener el login si falla el log
        error_log("Error al registrar log de auditoría: " . $e->getMessage());
    }

    sendJsonResponse(true, 'Login exitoso', ['user' => $user]);

} catch (Exception $e) {
    http_response_code(500);
    sendJsonResponse(false, 'Error: ' . $e->getMessage());
}

?>
