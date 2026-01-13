# Guía de Seguridad - TimeTracker v2.1.0

## Mejoras de Seguridad Implementadas

### 1. Variables de Entorno

El archivo `config.php` ya NO contiene credenciales hardcodeadas. Ahora usa variables de entorno.

**Configuración inicial:**

```bash
# Copiar el ejemplo
cp .env.example .env

# Editar con tus credenciales reales
nano .env
```

**Importante:** El archivo `.env` está en `.gitignore` y NO se sube al repositorio.

### 2. Autenticación Mejorada

Todos los PINs ahora se almacenan con hash bcrypt.

**Migración de PINs existentes:**

```bash
# Ejecutar SOLO UNA VEZ después del despliegue
http://timetracker.resol.dom/migrate-pins.php

# Verificar que funciona el login con todos los usuarios

# Eliminar el script
rm migrate-pins.php
```

**Creación de nuevos usuarios:**

Los PINs se hashean automáticamente al crear o actualizar usuarios.

### 3. Protección contra Fuerza Bruta

Sistema de rate limiting implementado:

- **Máximo de intentos:** 5 (configurable en `.env`)
- **Ventana de tiempo:** 15 minutos (configurable)
- **Bloqueo automático:** Temporal por IP

**Configuración:**

```env
RATE_LIMIT_ATTEMPTS=5
RATE_LIMIT_MINUTES=15
```

### 4. CORS Restringido

El acceso a la API está restringido a dominios específicos:

- Dominio principal (configurado en `.env`)
- localhost (solo para desarrollo)

**Configuración:**

```env
APP_DOMAIN=timetracker.resol.dom
```

### 5. Auditoría Completa

Todas las acciones críticas se registran:

- Login de usuarios (con IP)
- Creación/modificación/eliminación de entidades
- Timestamp de cada acción

**Consultar auditoría:**

```php
// Desde PHP
require_once 'audit-logger.php';
$logs = getAuditLog($pdo, [
    'userId' => 'u1',
    'action' => 'delete',
    'startDate' => '2026-01-01'
], 100);
```

### 6. Validaciones de Negocio

Validaciones implementadas:

- ✅ Horas entre 0 y 24
- ✅ Fechas no futuras (últimos 12 meses)
- ✅ Proyectos activos solamente
- ✅ Usuarios con acceso al proyecto
- ✅ PINs mínimo 4 caracteres

### 7. Gestión de Errores

Los errores de producción NO exponen información sensible:

```env
# Desarrollo
APP_ENV=development
APP_DEBUG=true

# Producción
APP_ENV=production
APP_DEBUG=false
```

## Checklist de Seguridad Pre-Producción

### Antes del Despliegue

- [ ] Copiar `.env.example` a `.env` con credenciales reales
- [ ] Verificar `APP_DEBUG=false` en `.env`
- [ ] Cambiar contraseña de BD desde el default
- [ ] Configurar dominio correcto en `APP_DOMAIN`
- [ ] Revisar que `config.php` NO está en el repo

### Después del Despliegue

- [ ] Ejecutar `migrate-pins.php` (solo una vez)
- [ ] Verificar login con todos los usuarios
- [ ] Eliminar `migrate-pins.php` y `setup.php`
- [ ] Cambiar PIN del admin desde la UI
- [ ] Verificar permisos de archivos (644 para PHP, 755 para directorios)
- [ ] Configurar HTTPS con certificado SSL
- [ ] Configurar firewall (UFW) permitiendo solo 22, 80, 443
- [ ] Revisar logs: `/var/log/php-fpm.log`, `/var/log/nginx/error.log`

### Configuración del Servidor

```bash
# Permisos correctos
sudo chown -R www-data:www-data /var/www/timetracker
sudo chmod -R 755 /var/www/timetracker
sudo chmod 600 /var/www/timetracker/.env

# Deshabilitar listado de directorios en Nginx
# Ya está en timetracker.nginx.conf

# Instalar fail2ban (opcional pero recomendado)
sudo apt install fail2ban -y
```

## Backups de Seguridad

### Backup de Base de Datos (Automatizado)

```bash
# Crear cron job
crontab -e

# Agregar backup diario a las 2 AM
0 2 * * * mysqldump -u timetracker_user -p$(grep DB_PASS /var/www/timetracker/.env | cut -d '=' -f2) timetracker > /var/backups/timetracker_$(date +\%Y\%m\%d).sql

# Mantener solo últimos 30 días
0 3 * * * find /var/backups/timetracker_*.sql -mtime +30 -delete
```

## Monitoreo y Alertas

### Logs a Revisar

```bash
# Errores de aplicación
tail -f /var/log/php8.3-fpm.log

# Intentos de login fallidos (buscar rate limit blocks)
grep "Rate limit: Blocked" /var/log/php8.3-fpm.log

# Errores de base de datos
grep "Database error" /var/log/php8.3-fpm.log
```

### Auditoría de Accesos

```sql
-- Últimos 100 logins
SELECT user_id, ip_address, created_at
FROM audit_log
WHERE action = 'login'
ORDER BY created_at DESC
LIMIT 100;

-- Eliminaciones en las últimas 24h
SELECT user_id, entity, entity_id, created_at
FROM audit_log
WHERE action = 'delete'
AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- IPs bloqueadas actualmente
SELECT identifier, action, blocked_until, attempts
FROM rate_limits
WHERE blocked_until > NOW();
```

## Respuesta a Incidentes

### Si detectas acceso no autorizado:

1. **Bloquear acceso inmediatamente:**
   ```bash
   # Cambiar passwords de BD
   mysql -u root -p
   ALTER USER 'timetracker_user'@'localhost' IDENTIFIED BY 'NUEVA_PASSWORD_FUERTE';

   # Actualizar .env
   nano /var/www/timetracker/.env
   ```

2. **Revisar logs de auditoría:**
   ```sql
   SELECT * FROM audit_log
   WHERE created_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR)
   ORDER BY created_at DESC;
   ```

3. **Resetear rate limits:**
   ```sql
   TRUNCATE TABLE rate_limits;
   ```

4. **Cambiar PINs de usuarios comprometidos:**
   Desde la interfaz de administración.

## Contacto para Reportar Vulnerabilidades

Para reportar problemas de seguridad, contactar al administrador del sistema.

---

**Última actualización:** 2026-01-13
**Versión:** 2.1.0
