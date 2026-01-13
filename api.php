<?php
/**
 * Time Tracker - API Backend (MySQL)
 * v2.0.1 - Maneja todas las operaciones CRUD
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$path = isset($_GET['path']) ? $_GET['path'] : '';
$input = json_decode(file_get_contents('php://input'), true);

// Log para debug (quitar en producción)
// error_log("API Request: $method $path " . json_encode($input));

try {
    switch ($path) {
        
        // ========== COMPANIES ==========
        case 'companies':
            if ($method === 'GET') {
                $stmt = $pdo->query("SELECT * FROM companies ORDER BY code");
                echo json_encode($stmt->fetchAll());
            } elseif ($method === 'POST') {
                if (empty($input['id']) || empty($input['code']) || empty($input['name'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }
                $stmt = $pdo->prepare("INSERT INTO companies (id, code, name) VALUES (?, ?, ?)");
                $stmt->execute([$input['id'], $input['code'], $input['name']]);
                echo json_encode(['success' => true, 'id' => $input['id']]);
            } elseif ($method === 'PUT') {
                if (empty($input['id']) || empty($input['code']) || empty($input['name'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }
                $stmt = $pdo->prepare("UPDATE companies SET code = ?, name = ? WHERE id = ?");
                $stmt->execute([$input['code'], $input['name'], $input['id']]);
                if ($stmt->rowCount() === 0) {
                    http_response_code(404);
                    echo json_encode(['error' => 'Empresa no encontrada']);
                } else {
                    echo json_encode(['success' => true]);
                }
            } elseif ($method === 'DELETE') {
                $id = isset($input['id']) ? $input['id'] : null;
                if (!$id) {
                    http_response_code(400);
                    echo json_encode(['error' => 'ID requerido']);
                    break;
                }
                $stmt = $pdo->prepare("DELETE FROM companies WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true]);
            }
            break;

        // ========== DEPTS ==========
        case 'depts':
            if ($method === 'GET') {
                $stmt = $pdo->query("SELECT * FROM depts ORDER BY code");
                echo json_encode($stmt->fetchAll());
            } elseif ($method === 'POST') {
                if (empty($input['id']) || empty($input['code']) || empty($input['name'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }
                $stmt = $pdo->prepare("INSERT INTO depts (id, code, name) VALUES (?, ?, ?)");
                $stmt->execute([$input['id'], $input['code'], $input['name']]);
                echo json_encode(['success' => true, 'id' => $input['id']]);
            } elseif ($method === 'PUT') {
                if (empty($input['id']) || empty($input['code']) || empty($input['name'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }
                $stmt = $pdo->prepare("UPDATE depts SET code = ?, name = ? WHERE id = ?");
                $stmt->execute([$input['code'], $input['name'], $input['id']]);
                if ($stmt->rowCount() === 0) {
                    http_response_code(404);
                    echo json_encode(['error' => 'Departamento no encontrado']);
                } else {
                    echo json_encode(['success' => true]);
                }
            } elseif ($method === 'DELETE') {
                $id = isset($input['id']) ? $input['id'] : null;
                if (!$id) {
                    http_response_code(400);
                    echo json_encode(['error' => 'ID requerido']);
                    break;
                }
                $stmt = $pdo->prepare("DELETE FROM depts WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true]);
            }
            break;

        // ========== PROJECTS ==========
        case 'projects':
            if ($method === 'GET') {
                $stmt = $pdo->query("SELECT * FROM projects ORDER BY code");
                echo json_encode($stmt->fetchAll());
            } elseif ($method === 'POST') {
                if (empty($input['id']) || empty($input['code']) || empty($input['name'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }
                $stmt = $pdo->prepare("INSERT INTO projects (id, code, name, client, companyId, status) VALUES (?, ?, ?, ?, ?, ?)");
                $stmt->execute([
                    $input['id'],
                    $input['code'],
                    $input['name'],
                    $input['client'] ?? '',
                    $input['companyId'] ?? null,
                    $input['status'] ?? 'active'
                ]);
                echo json_encode(['success' => true, 'id' => $input['id']]);
            } elseif ($method === 'PUT') {
                if (empty($input['id']) || empty($input['code']) || empty($input['name'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }
                $stmt = $pdo->prepare("UPDATE projects SET code = ?, name = ?, client = ?, companyId = ?, status = ? WHERE id = ?");
                $stmt->execute([
                    $input['code'],
                    $input['name'],
                    $input['client'] ?? '',
                    $input['companyId'] ?? null,
                    $input['status'] ?? 'active',
                    $input['id']
                ]);
                if ($stmt->rowCount() === 0) {
                    http_response_code(404);
                    echo json_encode(['error' => 'Proyecto no encontrado']);
                } else {
                    echo json_encode(['success' => true]);
                }
            } elseif ($method === 'DELETE') {
                $id = isset($input['id']) ? $input['id'] : null;
                if (!$id) {
                    http_response_code(400);
                    echo json_encode(['error' => 'ID requerido']);
                    break;
                }
                $stmt = $pdo->prepare("DELETE FROM projects WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true]);
            }
            break;

        // ========== TASKS ==========
        case 'tasks':
            if ($method === 'GET') {
                $stmt = $pdo->query("SELECT * FROM tasks ORDER BY sort_order, name");
                echo json_encode($stmt->fetchAll());
            } elseif ($method === 'POST') {
                $maxOrder = $pdo->query("SELECT COALESCE(MAX(sort_order), 0) FROM tasks")->fetchColumn();
                $stmt = $pdo->prepare("INSERT INTO tasks (id, name, color, sort_order) VALUES (?, ?, ?, ?)");
                $stmt->execute([$input['id'], $input['name'], $input['color'], $maxOrder + 1]);
                echo json_encode(['success' => true, 'id' => $input['id']]);
            } elseif ($method === 'PUT') {
                if (isset($input['reorder']) && $input['reorder']) {
                    $stmt = $pdo->prepare("UPDATE tasks SET sort_order = ? WHERE id = ?");
                    foreach ($input['order'] as $i => $id) {
                        $stmt->execute([$i, $id]);
                    }
                } else {
                    $stmt = $pdo->prepare("UPDATE tasks SET name = ?, color = ? WHERE id = ?");
                    $stmt->execute([$input['name'], $input['color'], $input['id']]);
                }
                echo json_encode(['success' => true]);
            } elseif ($method === 'DELETE') {
                $id = isset($_GET['id']) ? $_GET['id'] : (isset($input['id']) ? $input['id'] : null);
                $stmt = $pdo->prepare("DELETE FROM tasks WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true]);
            }
            break;

        // ========== USERS ==========
        case 'users':
            if ($method === 'GET') {
                $stmt = $pdo->query("SELECT * FROM users ORDER BY name");
                $users = $stmt->fetchAll();
                
                foreach ($users as &$u) {
                    $stmt2 = $pdo->prepare("SELECT projectId FROM user_projects WHERE userId = ?");
                    $stmt2->execute([$u['id']]);
                    $u['projects'] = $stmt2->fetchAll(PDO::FETCH_COLUMN);
                    
                    $stmt3 = $pdo->prepare("SELECT deptId FROM user_managed_depts WHERE userId = ?");
                    $stmt3->execute([$u['id']]);
                    $u['managedDepts'] = $stmt3->fetchAll(PDO::FETCH_COLUMN);
                }
                echo json_encode($users);
            } elseif ($method === 'POST') {
                if (empty($input['id']) || empty($input['name']) || empty($input['pin'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }

                try {
                    $pdo->beginTransaction();

                    $stmt = $pdo->prepare("INSERT INTO users (id, name, pin, profile, deptId, companyId, role) VALUES (?, ?, ?, ?, ?, ?, ?)");
                    $stmt->execute([
                        $input['id'],
                        $input['name'],
                        $input['pin'],
                        $input['profile'] ?? '',
                        $input['deptId'] ?: null,
                        $input['companyId'] ?: null,
                        $input['role'] ?? 'user'
                    ]);

                    if (!empty($input['projects'])) {
                        $stmt2 = $pdo->prepare("INSERT INTO user_projects (userId, projectId) VALUES (?, ?)");
                        foreach ($input['projects'] as $pid) {
                            $stmt2->execute([$input['id'], $pid]);
                        }
                    }

                    if (!empty($input['managedDepts'])) {
                        $stmt3 = $pdo->prepare("INSERT INTO user_managed_depts (userId, deptId) VALUES (?, ?)");
                        foreach ($input['managedDepts'] as $did) {
                            $stmt3->execute([$input['id'], $did]);
                        }
                    }

                    $pdo->commit();
                    echo json_encode(['success' => true, 'id' => $input['id']]);
                } catch (Exception $e) {
                    $pdo->rollBack();
                    throw $e;
                }
            } elseif ($method === 'PUT') {
                if (empty($input['id']) || empty($input['name']) || empty($input['pin'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos']);
                    break;
                }

                try {
                    $pdo->beginTransaction();

                    $stmt = $pdo->prepare("UPDATE users SET name = ?, pin = ?, profile = ?, deptId = ?, companyId = ?, role = ? WHERE id = ?");
                    $stmt->execute([
                        $input['name'],
                        $input['pin'],
                        $input['profile'] ?? '',
                        $input['deptId'] ?: null,
                        $input['companyId'] ?: null,
                        $input['role'] ?? 'user',
                        $input['id']
                    ]);

                    if ($stmt->rowCount() === 0) {
                        $pdo->rollBack();
                        http_response_code(404);
                        echo json_encode(['error' => 'Usuario no encontrado']);
                        break;
                    }

                    $pdo->prepare("DELETE FROM user_projects WHERE userId = ?")->execute([$input['id']]);
                    if (!empty($input['projects'])) {
                        $stmt2 = $pdo->prepare("INSERT INTO user_projects (userId, projectId) VALUES (?, ?)");
                        foreach ($input['projects'] as $pid) {
                            $stmt2->execute([$input['id'], $pid]);
                        }
                    }

                    $pdo->prepare("DELETE FROM user_managed_depts WHERE userId = ?")->execute([$input['id']]);
                    if (!empty($input['managedDepts'])) {
                        $stmt3 = $pdo->prepare("INSERT INTO user_managed_depts (userId, deptId) VALUES (?, ?)");
                        foreach ($input['managedDepts'] as $did) {
                            $stmt3->execute([$input['id'], $did]);
                        }
                    }

                    $pdo->commit();
                    echo json_encode(['success' => true]);
                } catch (Exception $e) {
                    $pdo->rollBack();
                    throw $e;
                }
            } elseif ($method === 'DELETE') {
                $id = isset($input['id']) ? $input['id'] : null;
                if (!$id) {
                    http_response_code(400);
                    echo json_encode(['error' => 'ID requerido']);
                    break;
                }
                // Las FK con CASCADE eliminan las relaciones automáticamente
                $pdo->prepare("DELETE FROM users WHERE id = ?")->execute([$id]);
                echo json_encode(['success' => true]);
            }
            break;

        // ========== ENTRIES ==========
        case 'entries':
            if ($method === 'GET') {
                $stmt = $pdo->query("SELECT * FROM entries ORDER BY date DESC");
                echo json_encode($stmt->fetchAll());
            } elseif ($method === 'POST') {
                // Verificar datos requeridos
                if (empty($input['id']) || empty($input['userId']) || empty($input['projectId']) || 
                    empty($input['taskId']) || empty($input['date'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Faltan campos requeridos', 'received' => $input]);
                    break;
                }
                
                $stmt = $pdo->prepare("INSERT INTO entries (id, userId, projectId, taskId, date, hours) VALUES (?, ?, ?, ?, ?, ?)");
                $stmt->execute([
                    $input['id'], 
                    $input['userId'], 
                    $input['projectId'], 
                    $input['taskId'], 
                    $input['date'], 
                    $input['hours'] ?? 0
                ]);
                echo json_encode(['success' => true, 'id' => $input['id']]);
            } elseif ($method === 'PUT') {
                if (empty($input['id'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'ID requerido']);
                    break;
                }
                // Validar rango de horas
                $hours = isset($input['hours']) ? floatval($input['hours']) : 0;
                if ($hours < 0 || $hours > 24) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Las horas deben estar entre 0 y 24']);
                    break;
                }
                $stmt = $pdo->prepare("UPDATE entries SET hours = ? WHERE id = ?");
                $stmt->execute([$hours, $input['id']]);
                if ($stmt->rowCount() === 0) {
                    http_response_code(404);
                    echo json_encode(['error' => 'Entrada no encontrada']);
                } else {
                    echo json_encode(['success' => true]);
                }
            } elseif ($method === 'DELETE') {
                $id = isset($input['id']) ? $input['id'] : null;
                if (!$id) {
                    http_response_code(400);
                    echo json_encode(['error' => 'ID requerido']);
                    break;
                }
                $stmt = $pdo->prepare("DELETE FROM entries WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true]);
            }
            break;

        // ========== AUTH ==========
        case 'login':
            if ($method === 'POST') {
                // Primero buscar el usuario por ID
                $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
                $stmt->execute([$input['userId']]);
                $user = $stmt->fetch();

                if ($user) {
                    // Verificar el PIN: soporta bcrypt (para Admin) o texto plano (para otros)
                    $pinValid = false;

                    // Si el PIN almacenado empieza con $2y$, es bcrypt
                    if (strpos($user['pin'], '$2y$') === 0) {
                        $pinValid = password_verify($input['pin'], $user['pin']);
                    } else {
                        // Comparación directa para PINs en texto plano
                        $pinValid = ($input['pin'] === $user['pin']);
                    }

                    if ($pinValid) {
                        $stmt2 = $pdo->prepare("SELECT projectId FROM user_projects WHERE userId = ?");
                        $stmt2->execute([$user['id']]);
                        $user['projects'] = $stmt2->fetchAll(PDO::FETCH_COLUMN);

                        $stmt3 = $pdo->prepare("SELECT deptId FROM user_managed_depts WHERE userId = ?");
                        $stmt3->execute([$user['id']]);
                        $user['managedDepts'] = $stmt3->fetchAll(PDO::FETCH_COLUMN);

                        echo json_encode(['success' => true, 'user' => $user]);
                    } else {
                        echo json_encode(['success' => false, 'error' => 'Credenciales incorrectas']);
                    }
                } else {
                    echo json_encode(['success' => false, 'error' => 'Credenciales incorrectas']);
                }
            }
            break;

        // ========== ALL DATA (para sync inicial) ==========
        case 'all':
            if ($method === 'GET') {
                $result = [
                    'companies' => $pdo->query("SELECT * FROM companies ORDER BY code")->fetchAll(),
                    'depts' => $pdo->query("SELECT * FROM depts ORDER BY code")->fetchAll(),
                    'projects' => $pdo->query("SELECT * FROM projects ORDER BY code")->fetchAll(),
                    'tasks' => $pdo->query("SELECT * FROM tasks ORDER BY sort_order, name")->fetchAll(),
                    'users' => [],
                    'entries' => $pdo->query("SELECT * FROM entries ORDER BY date DESC")->fetchAll()
                ];
                
                $users = $pdo->query("SELECT * FROM users ORDER BY name")->fetchAll();
                foreach ($users as &$u) {
                    $stmt = $pdo->prepare("SELECT projectId FROM user_projects WHERE userId = ?");
                    $stmt->execute([$u['id']]);
                    $u['projects'] = $stmt->fetchAll(PDO::FETCH_COLUMN);
                    
                    $stmt2 = $pdo->prepare("SELECT deptId FROM user_managed_depts WHERE userId = ?");
                    $stmt2->execute([$u['id']]);
                    $u['managedDepts'] = $stmt2->fetchAll(PDO::FETCH_COLUMN);
                }
                $result['users'] = $users;
                
                echo json_encode($result);
            }
            break;

        default:
            http_response_code(404);
            echo json_encode(['error' => 'Endpoint no encontrado: ' . $path]);
    }
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Error de base de datos',
        'message' => $e->getMessage(),
        'code' => $e->getCode()
    ]);
}
?>
