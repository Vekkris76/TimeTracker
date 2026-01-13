# TimeTracker - Entorno de Testing con Docker

## Requisitos Previos

- **Docker Desktop** instalado: https://www.docker.com/products/docker-desktop
- **Docker Compose** (incluido en Docker Desktop)
- Al menos 2GB de RAM disponible
- Puerto 8080, 8081 y 3306 libres

## Inicio Rápido

### 1. Clonar o descargar el proyecto

```bash
git clone https://github.com/Vekkris76/TimeTracker.git
cd TimeTracker
```

### 2. Crear archivo .env para Docker

```bash
# En Windows (PowerShell)
Copy-Item .env.docker .env

# En Linux/Mac
cp .env.docker .env
```

### 3. Iniciar el entorno

```bash
docker-compose up -d
```

Este comando:
- Descarga las imágenes necesarias (primera vez ~500MB)
- Crea los contenedores (web, db, phpmyadmin)
- Inicializa la base de datos con estructura y datos de ejemplo
- Inicia todos los servicios

### 4. Acceder a la aplicación

Espera unos segundos para que los servicios inicien completamente, luego:

- **TimeTracker**: http://localhost:8080
- **PHPMyAdmin**: http://localhost:8081
  - Usuario: `timetracker_user`
  - Password: `timetracker_pass_123`

### 5. Login de prueba

- **Usuario**: `u0`
- **PIN**: `admin`

## Comandos Útiles

### Ver logs en tiempo real

```bash
# Todos los servicios
docker-compose logs -f

# Solo el servidor web
docker-compose logs -f web

# Solo la base de datos
docker-compose logs -f db
```

### Detener el entorno

```bash
# Detener pero mantener datos
docker-compose stop

# Detener y eliminar contenedores (mantiene volúmenes)
docker-compose down

# Detener y eliminar TODO (incluida la BD)
docker-compose down -v
```

### Reiniciar servicios

```bash
# Reiniciar todo
docker-compose restart

# Reiniciar solo web
docker-compose restart web
```

### Acceder al contenedor

```bash
# Acceder al bash del contenedor web
docker-compose exec web bash

# Ejecutar comandos directamente
docker-compose exec web php -v
docker-compose exec web composer --version
```

### Limpiar y reconstruir

```bash
# Reconstruir las imágenes
docker-compose build --no-cache

# Limpiar todo y empezar de cero
docker-compose down -v
docker-compose up -d --build
```

## Estructura del Entorno Docker

```
TimeTracker/
├── docker-compose.yml        # Configuración de servicios
├── Dockerfile                 # Imagen personalizada PHP+Nginx
├── .env.docker                # Variables de entorno para Docker
├── docker/
│   ├── nginx.conf            # Configuración de Nginx
│   ├── start.sh              # Script de inicio
│   └── init.sql              # Inicialización de BD
```

## Servicios Disponibles

### 1. Web (PHP 8.3 + Nginx)

- **Puerto**: 8080
- **Tecnología**: PHP 8.3-FPM + Nginx
- **Volumen**: El código local se monta en el contenedor
- **Cambios en tiempo real**: Los cambios en archivos PHP se reflejan inmediatamente

### 2. Database (MySQL 8.0)

- **Puerto**: 3306
- **Usuario**: `timetracker_user`
- **Password**: `timetracker_pass_123`
- **Base de datos**: `timetracker`
- **Persistencia**: Los datos se guardan en un volumen Docker

### 3. PHPMyAdmin

- **Puerto**: 8081
- **Herramienta web para gestionar la base de datos**
- Útil para:
  - Ver estructura de tablas
  - Ejecutar queries SQL
  - Exportar/importar datos
  - Revisar logs de auditoría

## Testing y Desarrollo

### Probar las Mejoras de Seguridad

#### 1. Rate Limiting

```bash
# Intentar login fallido 10 veces rápidamente
# En el intento 11 deberías ver error de rate limit
```

#### 2. Auditoría

```sql
-- Conectar a PHPMyAdmin (localhost:8081)
-- Ejecutar query:
SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 20;
```

#### 3. Validaciones

```javascript
// Abrir consola del navegador (F12)
// Intentar registrar horas negativas o >24
// Deberías ver error de validación
```

### Ejecutar Migración de PINs

```bash
# Acceder al contenedor
docker-compose exec web bash

# Ejecutar migración
php migrate-pins.php

# O directamente:
docker-compose exec web php migrate-pins.php
```

### Instalar Composer Dependencies

```bash
docker-compose exec web composer install
```

## Solución de Problemas

### Puerto 8080 ya en uso

```bash
# Cambiar el puerto en docker-compose.yml
# Línea: "8080:80" -> "8090:80"
```

### Los cambios no se reflejan

```bash
# Reiniciar el servicio web
docker-compose restart web

# Si persiste, reconstruir
docker-compose up -d --build web
```

### Error de conexión a base de datos

```bash
# Verificar que la BD esté corriendo
docker-compose ps

# Ver logs de la BD
docker-compose logs db

# Reiniciar BD
docker-compose restart db
```

### Resetear completamente

```bash
# Eliminar TODO y empezar de cero
docker-compose down -v
docker system prune -a --volumes
docker-compose up -d --build
```

## Base de Datos de Prueba

El entorno incluye datos de ejemplo:

### Usuarios

| ID | Nombre | PIN | Rol |
|----|--------|-----|-----|
| u0 | Administrador | admin | admin |

### Empresas

| ID | Código | Nombre |
|----|--------|--------|
| c1 | DEMO | Empresa Demo |

### Proyectos

| ID | Código | Nombre | Cliente |
|----|--------|--------|---------|
| p1 | PROJ001 | Proyecto Demo | Cliente Demo |

### Tareas (9 predefinidas)

- Análisis, Desarrollo, Testing, Documentación, Reuniones, etc.

## Backup y Restore

### Exportar datos

```bash
# Backup de base de datos
docker-compose exec db mysqldump -u timetracker_user -ptimetracker_pass_123 timetracker > backup.sql
```

### Importar datos

```bash
# Restore de base de datos
docker-compose exec -T db mysql -u timetracker_user -ptimetracker_pass_123 timetracker < backup.sql
```

## Debugging

### Ver logs de PHP

```bash
# Logs de PHP-FPM
docker-compose exec web tail -f /usr/local/var/log/php-fpm.log

# Logs de Nginx
docker-compose exec web tail -f /var/log/nginx/timetracker_error.log
```

### Ejecutar PHP interactivo

```bash
docker-compose exec web php -a
```

### Ver variables de entorno

```bash
docker-compose exec web env | grep DB_
```

## Despliegue a Producción

**IMPORTANTE:** Este entorno es SOLO para testing y desarrollo.

Para producción, revisa:
- [README.md](README.md) - Instalación en servidor real
- [SECURITY.md](SECURITY.md) - Configuración de seguridad
- Cambiar passwords por defecto
- Configurar HTTPS
- Usar `.env.example` en lugar de `.env.docker`

## Recursos

- Docker Docs: https://docs.docker.com/
- MySQL Docker: https://hub.docker.com/_/mysql
- PHP Docker: https://hub.docker.com/_/php

---

**Versión**: 2.1.0
**Última actualización**: 2026-01-13
