<?php
// Incluir configuración
require_once '../config/config.php';

try {
    // Obtener datos del request
    $input = getJsonInput();
    
    // Validar datos requeridos
    $requiredFields = ['email', 'password', 'name', 'lastName', 'phone', 'address'];
    foreach ($requiredFields as $field) {
        if (empty($input[$field])) {
            sendJsonResponse(false, "Campo $field es requerido");
        }
    }
    
    $email = filter_var($input['email'], FILTER_VALIDATE_EMAIL);
    $password = password_hash($input['password'], PASSWORD_DEFAULT);
    $name = trim($input['name']);
    $lastName = trim($input['lastName']);
    $phone = trim($input['phone']);
    $address = trim($input['address']);
    
    if (!$email) {
        sendJsonResponse(false, 'Email inválido');
    }
    
    // Conectar a la base de datos
    $database = new Database();
    $db = $database->getConnection();
    
    // Verificar si el usuario ya existe
    $query = "SELECT id FROM usuarios WHERE email = ? OR telefono = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$email, $phone]);
    
    if ($stmt->fetch()) {
        sendJsonResponse(false, 'El usuario ya existe');
    }
    
    // Insertar nuevo usuario
    $uuid = uniqid('user_', true);
    $query = "
        INSERT INTO usuarios (uuid, nombre, apellido, email, telefono, hash_contrasena, creado_en) 
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$uuid, $name, $lastName, $email, $phone, $password]);
    $userId = $db->lastInsertId();
    
    // Insertar ubicación del usuario
    $query = "
        INSERT INTO ubicaciones_usuario (usuario_id, direccion, ciudad, departamento, pais, es_principal, creado_en) 
        VALUES (?, ?, 'Bogotá', 'Cundinamarca', 'Colombia', 1, NOW())
    ";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$userId, $address]);
    
    sendJsonResponse(true, 'Usuario registrado correctamente', ['userId' => $userId]);
    
} catch (Exception $e) {
    http_response_code(500);
    sendJsonResponse(false, 'Error: ' . $e->getMessage());
}
?>