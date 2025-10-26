<?php
require 'pingo/backend/config/database.php';
$db = (new Database())->getConnection();
$stmt = $db->query('DESCRIBE usuarios');
echo "Estructura de la tabla usuarios:\n\n";
while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}

echo "\n\nUsuarios existentes:\n\n";
$stmt = $db->query("SELECT id, nombre, email, telefono, tipo_usuario FROM usuarios LIMIT 5");
while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    print_r($row);
}
