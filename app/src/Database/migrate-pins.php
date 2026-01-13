<?php
/**
 * Script de migración: Convierte PINs en texto plano a hash bcrypt
 *
 * INSTRUCCIONES:
 * 1. Ejecutar SOLO UNA VEZ: http://timetracker.resol.dom/migrate-pins.php
 * 2. Verificar que todos los usuarios pueden login
 * 3. Eliminar este archivo después de ejecutar
 */

require_once __DIR__ . '/../../config/config.php';

header('Content-Type: application/json; charset=utf-8');

try {
    // Obtener todos los usuarios
    $stmt = $pdo->query("SELECT id, name, pin FROM users");
    $users = $stmt->fetchAll();

    $migrated = 0;
    $skipped = 0;

    foreach ($users as $user) {
        // Si el PIN ya está hasheado (bcrypt empieza con $2y$), skip
        if (strpos($user['pin'], '$2y$') === 0) {
            $skipped++;
            continue;
        }

        // Hashear el PIN
        $hashedPin = password_hash($user['pin'], PASSWORD_BCRYPT);

        // Actualizar en BD
        $updateStmt = $pdo->prepare("UPDATE users SET pin = ? WHERE id = ?");
        $updateStmt->execute([$hashedPin, $user['id']]);

        $migrated++;
    }

    echo json_encode([
        'success' => true,
        'migrated' => $migrated,
        'skipped' => $skipped,
        'total' => count($users),
        'message' => "Migración completada. $migrated PINs hasheados, $skipped ya estaban hasheados."
    ]);

} catch (Exception $e) {
    error_log('Migration error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'error' => 'Error durante la migración',
        'message' => $e->getMessage()
    ]);
}
?>
