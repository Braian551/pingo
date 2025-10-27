<?php
require 'pingo/backend/config/database.php';

try {
    $db = (new Database())->getConnection();

    // Datos del usuario de prueba
    $uuid = 'test_' . uniqid();
    $nombre = 'Usuario';
    $apellido = 'Prueba';
    $email = 'test' . rand(1000, 9999) . '@example.com';
    $telefono = '300' . rand(1000000, 9999999);
    $password = 'password123';
    $hash_contrasena = password_hash($password, PASSWORD_DEFAULT);
    $tipo_usuario = 'cliente'; // Cambiar a 'conductor' si necesitas un conductor

    // Insertar usuario
    $stmt = $db->prepare("INSERT INTO usuarios (uuid, nombre, apellido, email, telefono, hash_contrasena, tipo_usuario) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$uuid, $nombre, $apellido, $email, $telefono, $hash_contrasena, $tipo_usuario]);

    $user_id = $db->lastInsertId();

    echo "Usuario de prueba creado exitosamente:\n";
    echo "ID: $user_id\n";
    echo "UUID: $uuid\n";
    echo "Nombre: $nombre $apellido\n";
    echo "Email: $email\n";
    echo "Teléfono: $telefono\n";
    echo "Tipo: $tipo_usuario\n";
    echo "Contraseña: $password\n";

    // Si es conductor, crear detalles_conductor
    if ($tipo_usuario === 'conductor') {
        $stmt = $db->prepare("INSERT INTO detalles_conductor (usuario_id, vehiculo_tipo, vehiculo_placa) VALUES (?, 'motocicleta', 'TEST123')");
        $stmt->execute([$user_id]);
        echo "Detalles de conductor creados.\n";
    }

    // Crear ubicación de prueba
    $stmt = $db->prepare("INSERT INTO ubicaciones_usuario (usuario_id, latitud, longitud, direccion, ciudad, departamento, pais, es_principal) VALUES (?, 6.244654, -75.566504, 'Dirección de Prueba', 'Medellín', 'Antioquia', 'Colombia', 1)");
    $stmt->execute([$user_id]);

    echo "Ubicación de prueba creada.\n";

    // Crear solicitud de servicio de prueba
    $uuid_solicitud = 'solicitud_' . uniqid();
    $lat_recogida = 6.254618;
    $lon_recogida = -75.539557;
    $dir_recogida = 'Carrera 18B, Llanaditas';
    $lat_destino = 6.244654;
    $lon_destino = -75.566504;
    $dir_destino = 'Parque Lleras, El Poblado';
    $distancia = 8.50;
    $tiempo = 25;

    $stmt = $db->prepare("INSERT INTO solicitudes_servicio (uuid_solicitud, cliente_id, tipo_servicio, latitud_recogida, longitud_recogida, direccion_recogida, latitud_destino, longitud_destino, direccion_destino, distancia_estimada, tiempo_estimado, estado) VALUES (?, ?, 'transporte', ?, ?, ?, ?, ?, ?, ?, ?, 'pendiente')");
    $stmt->execute([$uuid_solicitud, $user_id, $lat_recogida, $lon_recogida, $dir_recogida, $lat_destino, $lon_destino, $dir_destino, $distancia, $tiempo]);

    $solicitud_id = $db->lastInsertId();

    echo "Solicitud de servicio creada:\n";
    echo "ID: $solicitud_id\n";
    echo "UUID: $uuid_solicitud\n";
    echo "Estado: pendiente\n";

    // Crear detalles del viaje
    $stmt = $db->prepare("INSERT INTO detalles_viaje (solicitud_id, numero_pasajeros, tarifa_estimada) VALUES (?, 1, 15000.00)");
    $stmt->execute([$solicitud_id]);

    echo "Detalles del viaje creados.\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?></content>
<parameter name="filePath">c:\Flutter\ping_go\create_test_user.php