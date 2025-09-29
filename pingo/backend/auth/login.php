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

    $query = "SELECT id, uuid, nombre, apellido, email, telefono, hash_contrasena FROM usuarios WHERE email = ? LIMIT 1";
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

    sendJsonResponse(true, 'Login exitoso', ['user' => $user]);

} catch (Exception $e) {
    http_response_code(500);
    sendJsonResponse(false, 'Error: ' . $e->getMessage());
}

?>
