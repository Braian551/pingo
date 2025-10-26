<?php
/**
 * Script para verificar y corregir el estado de aprobación del conductor
 */

// Crear conexión mysqli
$conn = new mysqli('localhost', 'root', 'root', 'pingo');
if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}
$conn->set_charset("utf8");

$conductor_id = 7; // ID del conductor a verificar

echo "=== Verificando estado del conductor ID: $conductor_id ===\n\n";

// Consultar estado actual
$stmt = $conn->prepare("
    SELECT 
        usuario_id,
        aprobado,
        estado_aprobacion,
        estado_verificacion,
        fecha_ultima_verificacion
    FROM detalles_conductor 
    WHERE usuario_id = ?
");
$stmt->bind_param("i", $conductor_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    die("❌ Conductor no encontrado\n");
}

$conductor = $result->fetch_assoc();

echo "Estado ACTUAL:\n";
echo "  - aprobado: " . $conductor['aprobado'] . "\n";
echo "  - estado_aprobacion: " . $conductor['estado_aprobacion'] . "\n";
echo "  - estado_verificacion: " . $conductor['estado_verificacion'] . "\n";
echo "  - fecha_ultima_verificacion: " . ($conductor['fecha_ultima_verificacion'] ?? 'NULL') . "\n\n";

// Si no está aprobado, corregir
if ($conductor['aprobado'] != 1 || $conductor['estado_verificacion'] != 'aprobado') {
    echo "⚠️  Estado incorrecto detectado. Corrigiendo...\n\n";
    
    // Actualizar a aprobado
    $stmt = $conn->prepare("
        UPDATE detalles_conductor 
        SET estado_verificacion = 'aprobado',
            estado_aprobacion = 'aprobado',
            aprobado = 1,
            fecha_ultima_verificacion = CURRENT_TIMESTAMP,
            actualizado_en = CURRENT_TIMESTAMP
        WHERE usuario_id = ?
    ");
    $stmt->bind_param("i", $conductor_id);
    
    if ($stmt->execute()) {
        echo "✅ Estado actualizado exitosamente\n\n";
        
        // Verificar actualización
        $stmt = $conn->prepare("
            SELECT 
                usuario_id,
                aprobado,
                estado_aprobacion,
                estado_verificacion,
                fecha_ultima_verificacion
            FROM detalles_conductor 
            WHERE usuario_id = ?
        ");
        $stmt->bind_param("i", $conductor_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $conductor = $result->fetch_assoc();
        
        echo "Estado CORREGIDO:\n";
        echo "  - aprobado: " . $conductor['aprobado'] . "\n";
        echo "  - estado_aprobacion: " . $conductor['estado_aprobacion'] . "\n";
        echo "  - estado_verificacion: " . $conductor['estado_verificacion'] . "\n";
        echo "  - fecha_ultima_verificacion: " . ($conductor['fecha_ultima_verificacion'] ?? 'NULL') . "\n";
    } else {
        echo "❌ Error al actualizar: " . $stmt->error . "\n";
    }
} else {
    echo "✅ El conductor ya está aprobado correctamente\n";
}

$conn->close();
echo "\n=== Proceso completado ===\n";
?>
