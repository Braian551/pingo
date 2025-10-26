<?php
require 'pingo/backend/config/database.php';
$db = (new Database())->getConnection();

echo "Estructura de la tabla detalles_conductor:\n\n";
$stmt = $db->query('DESCRIBE detalles_conductor');
while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}
