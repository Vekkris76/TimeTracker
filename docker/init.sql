-- TimeTracker Database Initialization
-- This script is automatically executed when the database container starts for the first time

USE timetracker;

-- Companies table
CREATE TABLE IF NOT EXISTS companies (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Departments table
CREATE TABLE IF NOT EXISTS depts (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    client VARCHAR(255) DEFAULT '',
    companyId VARCHAR(50),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (companyId) REFERENCES companies(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    color VARCHAR(7) DEFAULT '#3498db',
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    pin VARCHAR(255) NOT NULL,
    profile VARCHAR(50) DEFAULT '',
    deptId VARCHAR(50),
    companyId VARCHAR(50),
    role ENUM('user', 'manager', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deptId) REFERENCES depts(id) ON DELETE SET NULL,
    FOREIGN KEY (companyId) REFERENCES companies(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User-Projects relationship
CREATE TABLE IF NOT EXISTS user_projects (
    userId VARCHAR(50),
    projectId VARCHAR(50),
    PRIMARY KEY (userId, projectId),
    FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User-Managed Departments relationship
CREATE TABLE IF NOT EXISTS user_managed_depts (
    userId VARCHAR(50),
    deptId VARCHAR(50),
    PRIMARY KEY (userId, deptId),
    FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (deptId) REFERENCES depts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Time entries table
CREATE TABLE IF NOT EXISTS entries (
    id VARCHAR(50) PRIMARY KEY,
    userId VARCHAR(50) NOT NULL,
    projectId VARCHAR(50) NOT NULL,
    taskId VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    hours DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
    INDEX idx_user_date (userId, date),
    INDEX idx_project_date (projectId, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default tasks
INSERT INTO tasks (id, name, color, sort_order) VALUES
('t1', 'Análisis', '#3498db', 1),
('t2', 'Desarrollo', '#2ecc71', 2),
('t3', 'Testing', '#e74c3c', 3),
('t4', 'Documentación', '#f39c12', 4),
('t5', 'Reuniones', '#9b59b6', 5),
('t6', 'Formación', '#1abc9c', 6),
('t7', 'Soporte', '#34495e', 7),
('t8', 'Deployment', '#e67e22', 8),
('t9', 'Otros', '#95a5a6', 9)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Insert default admin user
-- Password: admin (bcrypt hashed)
INSERT INTO users (id, name, pin, profile, role) VALUES
('u0', 'Administrador', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'admin')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Insert sample company
INSERT INTO companies (id, code, name) VALUES
('c1', 'DEMO', 'Empresa Demo')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Insert sample department
INSERT INTO depts (id, code, name) VALUES
('d1', 'IT', 'Departamento IT')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Insert sample project
INSERT INTO projects (id, code, name, client, companyId, status) VALUES
('p1', 'PROJ001', 'Proyecto Demo', 'Cliente Demo', 'c1', 'active')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Grant admin access to sample project
INSERT INTO user_projects (userId, projectId) VALUES
('u0', 'p1')
ON DUPLICATE KEY UPDATE userId=VALUES(userId);
