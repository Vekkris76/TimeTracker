# Guía de Actualización a TimeTracker v2.1.0

## Resumen de Cambios

La versión 2.1.0 introduce mejoras críticas de seguridad y nuevas funcionalidades. Esta guía te ayudará a actualizar desde v2.0.x a v2.1.0.

## ⚠️ IMPORTANTE - Leer Antes de Actualizar

**BACKUP OBLIGATORIO:**
```bash
# Backup de base de datos
mysqldump -u timetracker_user -p timetracker > backup_pre_v2.1.0.sql

# Backup de archivos
tar -czf backup_files_pre_v2.1.0.tar.gz /var/www/timetracker/
```

## Cambios Principales

### 🔒 Seguridad

1. **Variables de entorno** - Credenciales ahora en archivo `.env`
2. **Hash de PINs** - Todos los PINs ahora usan bcrypt
3. **Rate limiting** - Protección contra fuerza bruta
4. **CORS restringido** - Acceso limitado a dominio interno
5. **Auditoría** - Log completo de acciones

### 📦 Nuevos Archivos

- `.env` - Configuración de entorno (CREAR MANUALMENTE)
- `env-loader.php` - Cargador de variables
- `rate-limiter.php` - Sistema anti fuerza bruta
- `audit-logger.php` - Sistema de auditoría
- `validators.php` - Validaciones de negocio
- `migrate-pins.php` - Script de migración (ejecutar UNA vez)
- `SECURITY.md` - Documentación de seguridad
- `composer.json` - Gestión de dependencias

### 🔧 Archivos Modificados

- `config.php` - Ahora usa variables de entorno
- `api.php` - Seguridad, validaciones y auditoría
- `.gitignore` - Excluye archivos sensibles

## Pasos de Actualización

### Paso 1: Descargar la Nueva Versión

```bash
cd /var/www/timetracker
git pull origin main
```

O descargar manualmente desde GitHub.

### Paso 2: Crear Archivo .env

```bash
# Copiar el ejemplo
cp .env.example .env

# Editar con tus credenciales REALES
nano .env
```

**Contenido mínimo de .env:**
```env
DB_HOST=localhost
DB_NAME=timetracker
DB_USER=timetracker_user
DB_PASS=TU_PASSWORD_REAL
DB_CHARSET=utf8mb4

APP_ENV=production
APP_DEBUG=false
APP_DOMAIN=timetracker.resol.dom

RATE_LIMIT_ATTEMPTS=5
RATE_LIMIT_MINUTES=15
```

### Paso 3: Configurar Permisos

```bash
# Proteger el archivo .env
chmod 600 /var/www/timetracker/.env
chown www-data:www-data /var/www/timetracker/.env

# Verificar permisos generales
chown -R www-data:www-data /var/www/timetracker
chmod -R 755 /var/www/timetracker
```

### Paso 4: Migrar PINs a Hash

**EJECUTAR SOLO UNA VEZ:**

```bash
# Opción 1: Desde navegador
http://timetracker.resol.dom/migrate-pins.php

# Opción 2: Desde línea de comandos
cd /var/www/timetracker
php migrate-pins.php
```

**Verificación:**
```json
{
  "success": true,
  "migrated": X,
  "skipped": 0,
  "total": X,
  "message": "Migración completada..."
}
```

### Paso 5: Verificar Login

**IMPORTANTE:** Prueba que todos los usuarios puedan hacer login con sus PINs actuales.

Los PINs NO cambian, solo se hashean internamente.

### Paso 6: Limpiar

```bash
# Eliminar script de migración
rm /var/www/timetracker/migrate-pins.php

# Eliminar setup.php si existe
rm /var/www/timetracker/setup.php
```

### Paso 7: Reiniciar Servicios

```bash
sudo systemctl restart php8.3-fpm
sudo systemctl restart nginx
```

### Paso 8: Verificar Funcionalidad

- [ ] Login funciona correctamente
- [ ] Se pueden crear/editar entradas de tiempo
- [ ] Dashboard muestra datos
- [ ] Validaciones funcionan (intentar horas negativas)
- [ ] Rate limiting funciona (intentar 6 logins fallidos)

## Verificación de Nuevas Funcionalidades

### 1. Auditoría

```sql
-- Conectar a MySQL
mysql -u timetracker_user -p timetracker

-- Ver tabla de auditoría
SHOW TABLES LIKE 'audit_log';

-- Ver últimas acciones
SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 10;
```

### 2. Rate Limiting

```sql
-- Ver tabla de rate limits
SHOW TABLES LIKE 'rate_limits';

-- Ver intentos bloqueados
SELECT * FROM rate_limits WHERE blocked_until > NOW();
```

### 3. Validaciones

Desde la interfaz web:
- Intentar registrar horas > 24 → Debe dar error
- Intentar registrar fecha futura → Debe dar error
- Intentar proyecto inactivo → Debe dar error

## Rollback (Si es Necesario)

Si algo sale mal, puedes volver atrás:

```bash
# 1. Restaurar archivos
cd /var/www/timetracker
git reset --hard <commit-anterior>

# 2. Restaurar base de datos
mysql -u timetracker_user -p timetracker < backup_pre_v2.1.0.sql

# 3. Reiniciar servicios
sudo systemctl restart php8.3-fpm nginx
```

## Problemas Comunes

### Error: "No se puede conectar a la base de datos"

**Solución:**
```bash
# Verificar .env
cat /var/www/timetracker/.env

# Verificar que config.php carga .env
php -r "require 'config.php'; echo 'OK';"
```

### Error: "Credenciales incorrectas" después de migración

**Solución:**
```bash
# Verificar que se ejecutó migrate-pins.php
# Los PINs deben empezar con $2y$ en la BD

mysql -u timetracker_user -p -e "SELECT id, name, LEFT(pin, 10) FROM timetracker.users;"
```

### Rate limit bloquea usuario legítimo

**Solución:**
```sql
-- Eliminar bloqueos
DELETE FROM rate_limits WHERE identifier = '<IP_ADDRESS>';

-- O resetear todo
TRUNCATE TABLE rate_limits;
```

## Configuración Opcional

### Cambiar Límites de Rate Limiting

En `.env`:
```env
RATE_LIMIT_ATTEMPTS=10
RATE_LIMIT_MINUTES=30
```

### Habilitar Modo Debug (Solo Desarrollo)

En `.env`:
```env
APP_ENV=development
APP_DEBUG=true
```

**⚠️ NUNCA en producción**

## Composer (Opcional)

Si quieres usar Composer:

```bash
# Instalar Composer
cd /var/www/timetracker
curl -sS https://getcomposer.org/installer | php
php composer.phar install

# O usar Composer global
composer install
```

## Monitoreo Post-Actualización

### Logs a Revisar

```bash
# Errores de PHP
tail -f /var/log/php8.3-fpm.log

# Errores de Nginx
tail -f /var/log/nginx/timetracker_error.log

# Buscar errores específicos
grep -i "error" /var/log/php8.3-fpm.log | tail -20
```

### Auditoría de Actualizaciones

```sql
-- Ver todas las acciones desde la actualización
SELECT user_id, action, entity, created_at
FROM audit_log
WHERE created_at >= 'FECHA_ACTUALIZACION'
ORDER BY created_at DESC;
```

## Soporte

Si encuentras problemas:

1. **Revisar logs** (PHP-FPM, Nginx)
2. **Verificar .env** (credenciales correctas)
3. **Probar en modo debug** (temporal)
4. **Revisar SECURITY.md** para configuración

## Checklist Final

- [ ] Backup completo realizado
- [ ] .env creado y configurado
- [ ] migrate-pins.php ejecutado
- [ ] migrate-pins.php eliminado
- [ ] Login verificado para todos los usuarios
- [ ] Servicios reiniciados
- [ ] Auditoría funcionando
- [ ] Rate limiting funcionando
- [ ] Validaciones funcionando
- [ ] Logs sin errores críticos

## Próximos Pasos

Revisa:
- [SECURITY.md](SECURITY.md) - Configuración de seguridad completa
- [DOCKER.md](DOCKER.md) - Entorno de testing local
- [README.md](README.md) - Documentación general

---

**Versión**: 2.1.0
**Fecha**: 2026-01-13
**Tiempo estimado de actualización**: 15-30 minutos
