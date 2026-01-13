<?php
/**
 * Time Tracker - Configuración de Base de Datos (MySQL)
 * Editar estos valores con los datos de vuestro servidor
 */

$db_host = 'localhost';             // Host del servidor MySQL
$db_name = 'timetracker';           // Nombre de la base de datos
$db_user = 'timetracker_user';      // Usuario MySQL
$db_pass = 'TuPasswordSeguro123!';  // Contraseña del usuario
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
    http_response_code(500);
    die(json_encode(['error' => 'Error de conexión: ' . $e->getMessage()]));
}
?>
