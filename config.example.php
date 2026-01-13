<?php
/**
 * Time Tracker - Configuración de Base de Datos (MySQL)
 *
 * INSTRUCCIONES:
 * 1. Copiar este archivo como config.php
 * 2. Editar las variables con tus credenciales reales
 * 3. NO subir config.php al repositorio (está en .gitignore)
 */

$db_host = 'localhost';             // Host del servidor MySQL
$db_name = 'timetracker';           // Nombre de la base de datos
$db_user = 'timetracker_user';      // Usuario MySQL
$db_pass = 'CAMBIAR_PASSWORD_AQUI'; // Contraseña del usuario
$db_charset = 'utf8mb4';

// No modificar a partir de aquí
try {
    $pdo = new PDO(
        "mysql:host=$db_host;dbname=$db_name;charset=$db_charset",
        $db_user,
        $db_pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
} catch (PDOException $e) {
    // En producción, no mostrar detalles del error
    error_log('Database connection error: ' . $e->getMessage());
    http_response_code(500);
    die(json_encode(['error' => 'Error de conexión a la base de datos']));
}
?>
