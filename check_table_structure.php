<?php
require_once 'pingo/backend/config/database.php';

$db = new Database();
$conn = $db->getConnection();

echo "Estructura de la tabla solicitudes_servicio:\n";
echo "=============================================\n";

$stmt = $conn->query('DESCRIBE solicitudes_servicio');
while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    echo $row['Field'] . " (" . $row['Type'] . ")\n";
}
