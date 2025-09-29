<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Configuración - USAR LA BASE DE DATOS CORRECTA (pingo2)
$config = [
    'db' => [
        'host' => 'localhost',
        'name' => 'pingo', // CAMBIADO de 'pingo' a 'pingo2'
        'user' => 'root',
        'pass' => 'root'
    ]
];

// Conectar a la base de datos
try {
    $pdo = new PDO(
        "mysql:host={$config['db']['host']};dbname={$config['db']['name']};charset=utf8",
        $config['db']['user'],
        $config['db']['pass']
    );
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error de conexión a la base de datos: ' . $e->getMessage()]);
    exit;
}

// Procesar la solicitud
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'JSON inválido']);
        exit;
    }
    
    $email = filter_var($input['email'] ?? '', FILTER_VALIDATE_EMAIL);
    $code = $input['code'] ?? '';
    
    if (!$email || empty($code)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Datos incompletos o inválidos']);
        exit;
    }
    
    try {
        // Verificar si la tabla existe
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'verification_codes'")->fetch();
        if (!$tableCheck) {
            throw new Exception("La tabla verification_codes no existe en la base de datos");
        }
        
        // Buscar el código en la base de datos
        $stmt = $pdo->prepare("SELECT * FROM verification_codes WHERE email = ? AND code = ? AND used = 0 AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1");
        $stmt->execute([$email, $code]);
        $verificationCode = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($verificationCode) {
            // Marcar el código como usado
            $updateStmt = $pdo->prepare("UPDATE verification_codes SET used = 1 WHERE id = ?");
            $updateStmt->execute([$verificationCode['id']]);
            
            echo json_encode(['success' => true, 'message' => 'Código verificado correctamente']);
        } else {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Código inválido o expirado']);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
        error_log("Error en verifi_code: " . $e->getMessage());
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
}
?>