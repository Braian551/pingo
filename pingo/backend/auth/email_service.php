<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
// Incluir configuración
require_once 'config/config.php';

try {
    // Obtener datos del request
    $input = getJsonInput();

    $email = filter_var($input['email'] ?? '', FILTER_VALIDATE_EMAIL);
    $code = $input['code'] ?? '';
    $userName = $input['userName'] ?? '';

    if (!$email || strlen($code) !== 6 || empty($userName)) {
        sendJsonResponse(false, 'Datos incompletos o inválidos');
    }

    // Conectar a la base de datos
    $database = new Database();
    $db = $database->getConnection();

    // Guardar el código en la base de datos
    $expires_at = date('Y-m-d H:i:s', strtotime('+10 minutes'));

    $query = "INSERT INTO verification_codes (email, code, expires_at) VALUES (?, ?, ?)";
    $stmt = $db->prepare($query);
    $stmt->execute([$email, $code, $expires_at]);

    // Enviar el correo electrónico (tu código existente de PHPMailer)
    require 'vendor/autoload.php';


    $mail = new PHPMailer(true);

    // Configuración SMTP (usa tus configuraciones actuales)
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'braianoquendurango@gmail.com';
    $mail->Password = 'nvok ghfu usmp apmc';
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = 587;

    // Configuración del correo
    $mail->setFrom('braianoquendurango@pinggo.com', 'PingGo');
    $mail->addAddress($email, $userName);

    $mail->isHTML(true);
    $mail->Subject = 'Tu código de verificación PingGo';
    $mail->Body = "
        <h2>Hola $userName,</h2>
        <p>Tu código de verificación para PingGo es:</p>
        <h1 style='color: #39FF14; font-size: 32px; text-align: center;'>$code</h1>
        <p>Este código expirará en 10 minutos.</p>
        <p>Si no solicitaste este código, por favor ignora este mensaje.</p>
        <br>
        <p>Saludos,<br>El equipo de PingGo</p>
    ";

    $mail->AltBody = "Hola $userName,\n\nTu código de verificación para PingGo es: $code\n\nEste código expirará en 10 minutos.\n\nSi no solicitaste este código, por favor ignora este mensaje.\n\nSaludos,\nEl equipo de PingGo";

    if ($mail->send()) {
        sendJsonResponse(true, 'Código enviado correctamente');
    } else {
        throw new Exception("Error al enviar email: " . $mail->ErrorInfo);
    }
} catch (Exception $e) {
    http_response_code(500);
    sendJsonResponse(false, 'Error: ' . $e->getMessage());
}
