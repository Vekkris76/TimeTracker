<?php
/**
 * Audit Logger - Sistema de auditoría
 *
 * Registra todas las acciones importantes de usuarios
 */

/**
 * Registra una acción en el log de auditoría
 *
 * @param PDO $pdo Conexión a la base de datos
 * @param string $userId ID del usuario que realiza la acción
 * @param string $action Tipo de acción (login, create, update, delete)
 * @param string $entity Entidad afectada (users, projects, entries, etc)
 * @param string|null $entityId ID de la entidad afectada
 * @param array $details Detalles adicionales
 */
function logAudit($pdo, $userId, $action, $entity, $entityId = null, $details = []) {
    static $tableCreated = false;

    // Crear tabla si no existe (solo una vez por request)
    if (!$tableCreated) {
        createAuditTableIfNeeded($pdo);
        $tableCreated = true;
    }

    try {
        $stmt = $pdo->prepare("
            INSERT INTO audit_log (user_id, action, entity, entity_id, details, ip_address, user_agent, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        ");

        $stmt->execute([
            $userId,
            $action,
            $entity,
            $entityId,
            json_encode($details),
            $_SERVER['REMOTE_ADDR'] ?? null,
            $_SERVER['HTTP_USER_AGENT'] ?? null
        ]);
    } catch (PDOException $e) {
        // No interrumpir la operación principal si falla el log
        error_log('Audit log error: ' . $e->getMessage());
    }
}

/**
 * Crea la tabla de auditoría si no existe
 */
function createAuditTableIfNeeded($pdo) {
    $sql = "CREATE TABLE IF NOT EXISTS audit_log (
        id BIGINT AUTO_INCREMENT PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        action VARCHAR(50) NOT NULL,
        entity VARCHAR(50) NOT NULL,
        entity_id VARCHAR(50) NULL,
        details TEXT NULL,
        ip_address VARCHAR(45) NULL,
        user_agent VARCHAR(255) NULL,
        created_at DATETIME NOT NULL,
        INDEX idx_user_id (user_id),
        INDEX idx_action (action),
        INDEX idx_entity (entity, entity_id),
        INDEX idx_created_at (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

    try {
        $pdo->exec($sql);
    } catch (PDOException $e) {
        error_log('Audit table creation error: ' . $e->getMessage());
    }
}

/**
 * Obtiene el log de auditoría con filtros
 *
 * @param PDO $pdo
 * @param array $filters ['userId' => 'u1', 'action' => 'delete', 'startDate' => '2026-01-01']
 * @param int $limit
 * @return array
 */
function getAuditLog($pdo, $filters = [], $limit = 100) {
    $where = [];
    $params = [];

    if (!empty($filters['userId'])) {
        $where[] = "user_id = ?";
        $params[] = $filters['userId'];
    }

    if (!empty($filters['action'])) {
        $where[] = "action = ?";
        $params[] = $filters['action'];
    }

    if (!empty($filters['entity'])) {
        $where[] = "entity = ?";
        $params[] = $filters['entity'];
    }

    if (!empty($filters['startDate'])) {
        $where[] = "created_at >= ?";
        $params[] = $filters['startDate'];
    }

    if (!empty($filters['endDate'])) {
        $where[] = "created_at <= ?";
        $params[] = $filters['endDate'];
    }

    $whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';
    $sql = "SELECT * FROM audit_log $whereClause ORDER BY created_at DESC LIMIT ?";
    $params[] = $limit;

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    } catch (PDOException $e) {
        error_log('Get audit log error: ' . $e->getMessage());
        return [];
    }
}
?>
