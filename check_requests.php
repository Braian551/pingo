<?php
require 'pingo/backend/config/database.php';
$db = (new Database())->getConnection();
$stmt = $db->query('SELECT id, cliente_id, estado, direccion_recogida, direccion_destino FROM solicitudes_servicio WHERE estado = "pendiente"');
echo "Solicitudes pendientes:\n";
while($row = $stmt->fetch()) {
    print_r($row);
}
?>