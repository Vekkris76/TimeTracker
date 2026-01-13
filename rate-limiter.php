<?php
/**
 * Rate Limiter - Protección contra fuerza bruta
 *
 * Limita el número de intentos de login por IP
 */

class RateLimiter {
    private $pdo;
    private $maxAttempts;
    private $timeWindow; // en minutos

    public function __construct($pdo) {
        $this->pdo = $pdo;
        require_once __DIR__ . '/env-loader.php';
        $this->maxAttempts = (int)env('RATE_LIMIT_ATTEMPTS', 5);
        $this->timeWindow = (int)env('RATE_LIMIT_MINUTES', 15);

        // Crear tabla si no existe
        $this->createTableIfNeeded();
    }

    private function createTableIfNeeded() {
        $sql = "CREATE TABLE IF NOT EXISTS rate_limits (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(255) NOT NULL,
            action VARCHAR(50) NOT NULL,
            attempts INT DEFAULT 0,
            last_attempt DATETIME NOT NULL,
            blocked_until DATETIME NULL,
            INDEX idx_identifier_action (identifier, action),
            INDEX idx_blocked_until (blocked_until)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        try {
            $this->pdo->exec($sql);
        } catch (PDOException $e) {
            error_log('Rate limiter table creation error: ' . $e->getMessage());
        }
    }

    /**
     * Verifica si el identificador puede realizar la acción
     *
     * @param string $identifier IP o user ID
     * @param string $action Tipo de acción (ej: 'login')
     * @return bool true si puede continuar, false si está bloqueado
     */
    public function checkLimit($identifier, $action) {
        // Limpiar registros antiguos
        $this->cleanOldRecords();

        $stmt = $this->pdo->prepare("
            SELECT attempts, blocked_until
            FROM rate_limits
            WHERE identifier = ? AND action = ?
        ");
        $stmt->execute([$identifier, $action]);
        $record = $stmt->fetch();

        if (!$record) {
            return true; // No hay registro, puede continuar
        }

        // Si está bloqueado, verificar si el bloqueo expiró
        if ($record['blocked_until']) {
            $blockedUntil = new DateTime($record['blocked_until']);
            $now = new DateTime();

            if ($now < $blockedUntil) {
                return false; // Aún bloqueado
            } else {
                // Bloqueo expirado, resetear
                $this->resetLimit($identifier, $action);
                return true;
            }
        }

        // Verificar número de intentos
        if ($record['attempts'] >= $this->maxAttempts) {
            // Bloquear
            $this->blockIdentifier($identifier, $action);
            return false;
        }

        return true;
    }

    /**
     * Registra un intento fallido
     */
    public function recordAttempt($identifier, $action) {
        $stmt = $this->pdo->prepare("
            SELECT id, attempts
            FROM rate_limits
            WHERE identifier = ? AND action = ?
        ");
        $stmt->execute([$identifier, $action]);
        $record = $stmt->fetch();

        if ($record) {
            // Incrementar intentos
            $newAttempts = $record['attempts'] + 1;
            $updateStmt = $this->pdo->prepare("
                UPDATE rate_limits
                SET attempts = ?, last_attempt = NOW()
                WHERE id = ?
            ");
            $updateStmt->execute([$newAttempts, $record['id']]);

            // Si alcanzó el límite, bloquear
            if ($newAttempts >= $this->maxAttempts) {
                $this->blockIdentifier($identifier, $action);
            }
        } else {
            // Crear nuevo registro
            $insertStmt = $this->pdo->prepare("
                INSERT INTO rate_limits (identifier, action, attempts, last_attempt)
                VALUES (?, ?, 1, NOW())
            ");
            $insertStmt->execute([$identifier, $action]);
        }
    }

    /**
     * Bloquea un identificador temporalmente
     */
    private function blockIdentifier($identifier, $action) {
        $stmt = $this->pdo->prepare("
            UPDATE rate_limits
            SET blocked_until = DATE_ADD(NOW(), INTERVAL ? MINUTE)
            WHERE identifier = ? AND action = ?
        ");
        $stmt->execute([$this->timeWindow, $identifier, $action]);

        error_log("Rate limit: Blocked $identifier for $action until " .
            date('Y-m-d H:i:s', strtotime("+{$this->timeWindow} minutes")));
    }

    /**
     * Resetea el límite para un identificador (después de login exitoso)
     */
    public function resetLimit($identifier, $action) {
        $stmt = $this->pdo->prepare("
            DELETE FROM rate_limits
            WHERE identifier = ? AND action = ?
        ");
        $stmt->execute([$identifier, $action]);
    }

    /**
     * Limpia registros antiguos (más de 24 horas)
     */
    private function cleanOldRecords() {
        // Solo limpiar ocasionalmente (10% de probabilidad)
        if (rand(1, 10) !== 1) {
            return;
        }

        try {
            $this->pdo->exec("
                DELETE FROM rate_limits
                WHERE last_attempt < DATE_SUB(NOW(), INTERVAL 24 HOUR)
                AND (blocked_until IS NULL OR blocked_until < NOW())
            ");
        } catch (PDOException $e) {
            error_log('Rate limiter cleanup error: ' . $e->getMessage());
        }
    }
}
?>
