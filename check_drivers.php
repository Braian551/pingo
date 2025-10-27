<?php
require 'pingo/backend/config/database.php';
$db = (new Database())->getConnection();
$stmt = $db->query('SELECT dc.disponible, dc.latitud_actual, dc.longitud_actual, u.nombre FROM detalles_conductor dc JOIN usuarios u ON dc.usuario_id = u.id WHERE u.tipo_usuario = "conductor"');
echo "Conductores:\n";
while($row = $stmt->fetch()) {
    print_r($row);
}
?>