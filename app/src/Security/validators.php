<?php
/**
 * Validators - Validación de datos de negocio
 */

class Validators {
    /**
     * Valida que las horas estén en rango válido
     */
    public static function validateHours($hours) {
        $hours = floatval($hours);

        if ($hours < 0) {
            return ['valid' => false, 'error' => 'Las horas no pueden ser negativas'];
        }

        if ($hours > 24) {
            return ['valid' => false, 'error' => 'Las horas no pueden exceder 24 en un día'];
        }

        return ['valid' => true];
    }

    /**
     * Valida que la fecha sea válida y no futura (configurable)
     */
    public static function validateDate($date, $allowFuture = false) {
        // Validar formato
        $dateObj = DateTime::createFromFormat('Y-m-d', $date);
        if (!$dateObj || $dateObj->format('Y-m-d') !== $date) {
            return ['valid' => false, 'error' => 'Formato de fecha inválido. Use YYYY-MM-DD'];
        }

        // Validar que no sea futura (si no se permite)
        if (!$allowFuture) {
            $now = new DateTime();
            if ($dateObj > $now) {
                return ['valid' => false, 'error' => 'No se pueden registrar horas en fechas futuras'];
            }
        }

        // Validar que no sea demasiado antigua (más de 1 año)
        $oneYearAgo = new DateTime('-1 year');
        if ($dateObj < $oneYearAgo) {
            return ['valid' => false, 'error' => 'No se pueden registrar horas de hace más de 1 año'];
        }

        return ['valid' => true];
    }

    /**
     * Valida que el proyecto esté activo
     */
    public static function validateProjectStatus($pdo, $projectId) {
        $stmt = $pdo->prepare("SELECT status FROM projects WHERE id = ?");
        $stmt->execute([$projectId]);
        $project = $stmt->fetch();

        if (!$project) {
            return ['valid' => false, 'error' => 'Proyecto no encontrado'];
        }

        if ($project['status'] !== 'active') {
            return ['valid' => false, 'error' => 'No se pueden registrar horas en proyectos inactivos'];
        }

        return ['valid' => true];
    }

    /**
     * Valida que el usuario tenga acceso al proyecto
     */
    public static function validateUserProjectAccess($pdo, $userId, $projectId) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count
            FROM user_projects
            WHERE userId = ? AND projectId = ?
        ");
        $stmt->execute([$userId, $projectId]);
        $result = $stmt->fetch();

        if ($result['count'] == 0) {
            return ['valid' => false, 'error' => 'El usuario no tiene acceso a este proyecto'];
        }

        return ['valid' => true];
    }

    /**
     * Valida el total de horas por día (no exceder 24h)
     */
    public static function validateDailyHours($pdo, $userId, $date, $excludeEntryId = null) {
        $sql = "
            SELECT SUM(hours) as total
            FROM entries
            WHERE userId = ? AND date = ?
        ";
        $params = [$userId, $date];

        if ($excludeEntryId) {
            $sql .= " AND id != ?";
            $params[] = $excludeEntryId;
        }

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetch();

        $total = floatval($result['total'] ?? 0);

        if ($total > 24) {
            return ['valid' => false, 'error' => "El total de horas para el día $date excede las 24 horas"];
        }

        return ['valid' => true, 'totalHours' => $total];
    }

    /**
     * Valida un PIN (mínimo 4 caracteres)
     */
    public static function validatePin($pin) {
        if (strlen($pin) < 4) {
            return ['valid' => false, 'error' => 'El PIN debe tener al menos 4 caracteres'];
        }

        return ['valid' => true];
    }

    /**
     * Valida código único (no duplicado)
     */
    public static function validateUniqueCode($pdo, $table, $code, $excludeId = null) {
        $sql = "SELECT COUNT(*) as count FROM $table WHERE code = ?";
        $params = [$code];

        if ($excludeId) {
            $sql .= " AND id != ?";
            $params[] = $excludeId;
        }

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetch();

        if ($result['count'] > 0) {
            return ['valid' => false, 'error' => 'El código ya existe'];
        }

        return ['valid' => true];
    }

    /**
     * Sanitiza una cadena de texto
     */
    public static function sanitizeString($str) {
        return trim(strip_tags($str));
    }

    /**
     * Valida un email (si se implementa en el futuro)
     */
    public static function validateEmail($email) {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return ['valid' => false, 'error' => 'Email inválido'];
        }

        return ['valid' => true];
    }
}
?>
