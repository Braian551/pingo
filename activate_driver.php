<?php
require 'pingo/backend/config/database.php';
$db = (new Database())->getConnection();
$db->query('UPDATE detalles_conductor SET disponible = 1 WHERE usuario_id = 7');
echo 'Conductor activado.';
?>