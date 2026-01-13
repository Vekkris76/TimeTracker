# ✅ TimeTracker v2.1.0 - Production Deployment Checklist

## Pre-Deployment (1-2 días antes)

### 📋 Planning
- [ ] Seleccionar ventana de mantenimiento (fuera de horas laborales recomendado)
- [ ] Notificar a usuarios sobre el mantenimiento programado
- [ ] Asignar tiempo estimado: 30-45 minutos
- [ ] Preparar plan de rollback

### 🔍 Environment Verification
- [ ] Ejecutar `./pre-deploy.sh` sin errores
- [ ] Verificar versión de PHP >= 8.1
- [ ] Verificar Nginx está instalado y configurado
- [ ] Verificar MySQL/MariaDB funcionando
- [ ] Verificar espacio en disco suficiente (>1GB libre)
- [ ] Verificar permisos de usuario www-data

### 💾 Backups
- [ ] Backup completo de base de datos
  ```bash
  mysqldump -u timetracker_user -p timetracker > backup_$(date +%Y%m%d).sql
  ```
- [ ] Backup de archivos del proyecto
  ```bash
  tar -czf backup_files_$(date +%Y%m%d).tar.gz /var/www/timetracker/
  ```
- [ ] Verificar que los backups son válidos y accesibles
- [ ] Guardar backups en ubicación segura (fuera del servidor)

### 📝 Documentation Review
- [ ] Leer [UPGRADE_v2.1.0.md](UPGRADE_v2.1.0.md) completamente
- [ ] Leer [SECURITY.md](SECURITY.md) checklist de seguridad
- [ ] Imprimir/guardar procedimiento de rollback

---

## Deployment Day

### 🚀 Phase 1: Preparation (5 min)

- [ ] Conectar al servidor via SSH
  ```bash
  ssh user@timetracker.resol.dom
  ```
- [ ] Cambiar al directorio del proyecto
  ```bash
  cd /var/www/timetracker
  ```
- [ ] Verificar que estás en el usuario correcto
- [ ] Ejecutar pre-deployment check:
  ```bash
  sudo bash pre-deploy.sh
  ```
- [ ] **STOP SI HAY ERRORES CRÍTICOS**

### 📦 Phase 2: Deployment (10-15 min)

#### Opción A: Deployment Automatizado (Recomendado)
- [ ] Ejecutar script de deployment:
  ```bash
  sudo bash deploy-production.sh
  ```
- [ ] Revisar cada paso del script
- [ ] **STOP SI ALGO FALLA**

#### Opción B: Deployment Manual
Si prefieres control paso a paso:

- [ ] **Backup automático:**
  ```bash
  mysqldump -u user -p timetracker > /var/backups/timetracker/db_$(date +%Y%m%d_%H%M%S).sql
  tar -czf /var/backups/timetracker/files_$(date +%Y%m%d_%H%M%S).tar.gz .
  ```

- [ ] **Pull código:**
  ```bash
  git fetch origin
  git pull origin main
  ```

- [ ] **Crear .env si no existe:**
  ```bash
  cp .env.example .env
  nano .env
  ```
  Configurar:
  - `DB_*` variables con credenciales reales
  - `APP_ENV=production`
  - `APP_DEBUG=false`
  - `APP_DOMAIN=timetracker.resol.dom`

- [ ] **Permisos:**
  ```bash
  sudo chown -R www-data:www-data /var/www/timetracker
  sudo chmod -R 755 /var/www/timetracker
  sudo chmod 600 /var/www/timetracker/.env
  ```

- [ ] **Migrar PINs (solo primera vez):**
  ```bash
  php migrate-pins.php
  # Verificar salida: {"success":true,...}
  rm migrate-pins.php
  ```

- [ ] **Limpiar archivos sensibles:**
  ```bash
  rm -f setup.php test_login.php
  ```

- [ ] **Reiniciar servicios:**
  ```bash
  sudo systemctl restart php8.3-fpm
  sudo nginx -t && sudo systemctl restart nginx
  ```

### ✅ Phase 3: Verification (10-15 min)

- [ ] **Ejecutar post-deployment check:**
  ```bash
  sudo bash post-deploy-check.sh
  ```

- [ ] **Verificar servicios:**
  ```bash
  sudo systemctl status nginx
  sudo systemctl status php8.3-fpm
  sudo systemctl status mysql
  ```

- [ ] **Probar API manualmente:**
  ```bash
  curl http://localhost/api.php?path=all | python3 -m json.tool
  ```
  Debe devolver JSON con companies, depts, projects, etc.

- [ ] **Probar login desde navegador:**
  - Abrir: http://timetracker.resol.dom
  - Login con usuario de prueba
  - Verificar que funciona

- [ ] **Verificar audit log:**
  ```sql
  SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 10;
  ```

- [ ] **Revisar logs sin errores:**
  ```bash
  tail -50 /var/log/php8.3-fpm.log
  tail -50 /var/log/nginx/error.log
  ```

### 🧪 Phase 4: Testing (10 min)

- [ ] **Login de todos los tipos de usuarios:**
  - [ ] Admin
  - [ ] Manager
  - [ ] User regular

- [ ] **Funcionalidades core:**
  - [ ] Ver timesheet semanal
  - [ ] Crear entrada de tiempo
  - [ ] Editar entrada existente
  - [ ] Ver dashboard (Manager/Admin)
  - [ ] Ver estadísticas personales

- [ ] **Nuevas validaciones:**
  - [ ] Intentar horas negativas → debe fallar
  - [ ] Intentar fecha futura → debe fallar
  - [ ] Intentar horas > 24 → debe fallar

- [ ] **Rate limiting:**
  - [ ] Intentar 6 logins fallidos → debe bloquear
  - [ ] Verificar en tabla rate_limits

---

## Post-Deployment (1-3 días después)

### 📊 Monitoring

- [ ] **Día 1 - Monitoreo activo cada 2-4 horas:**
  - [ ] Revisar logs de errores
  - [ ] Revisar audit_log para actividad anormal
  - [ ] Verificar que no hay usuarios bloqueados injustamente
  - [ ] Recopilar feedback de usuarios

- [ ] **Día 2-3 - Monitoreo pasivo 1-2 veces al día:**
  - [ ] Revisar logs
  - [ ] Verificar métricas de uso
  - [ ] Confirmar que no hay issues reportados

### 🔍 Audit & Security Review

- [ ] **Revisar audit log:**
  ```sql
  -- Logins en las últimas 24h
  SELECT user_id, COUNT(*) as login_count,
         MAX(created_at) as last_login
  FROM audit_log
  WHERE action = 'login'
    AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
  GROUP BY user_id;

  -- Acciones de eliminación
  SELECT user_id, entity, entity_id, created_at
  FROM audit_log
  WHERE action = 'delete'
    AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);
  ```

- [ ] **Revisar rate limits:**
  ```sql
  SELECT identifier, action, attempts, blocked_until
  FROM rate_limits
  WHERE blocked_until > NOW() OR attempts > 0;
  ```

- [ ] **Verificar backups automáticos funcionando**

### 📝 Documentation Update

- [ ] Actualizar documentación interna con:
  - Nueva URL (si cambió)
  - Cambios en procedimientos
  - Problemas encontrados y soluciones

- [ ] Notificar a usuarios sobre:
  - Nuevas features (si aplica)
  - Mejoras de seguridad implementadas
  - Que todo está funcionando correctamente

---

## Rollback Procedure (Si algo sale mal)

### 🔙 Emergency Rollback

**Solo ejecutar si hay problemas críticos que impiden el uso de la aplicación**

1. **Detener servicios:**
   ```bash
   sudo systemctl stop nginx
   sudo systemctl stop php8.3-fpm
   ```

2. **Restaurar base de datos:**
   ```bash
   mysql -u timetracker_user -p timetracker < /var/backups/timetracker/db_TIMESTAMP.sql
   ```

3. **Restaurar archivos:**
   ```bash
   cd /var/www/timetracker
   rm -rf ./*
   tar -xzf /var/backups/timetracker/files_TIMESTAMP.tar.gz
   ```

4. **Restaurar permisos:**
   ```bash
   sudo chown -R www-data:www-data /var/www/timetracker
   sudo chmod -R 755 /var/www/timetracker
   ```

5. **Reiniciar servicios:**
   ```bash
   sudo systemctl start php8.3-fpm
   sudo systemctl start nginx
   ```

6. **Verificar:**
   ```bash
   curl http://localhost/api.php?path=all
   ```

7. **Notificar a usuarios**

---

## Success Criteria

El deployment se considera exitoso si:

- ✅ Todos los checks de post-deployment pasan
- ✅ Usuarios pueden hacer login
- ✅ No hay errores en logs
- ✅ API responde correctamente
- ✅ Rate limiting funciona
- ✅ Audit log registra acciones
- ✅ No hay degradación de performance
- ✅ Backups están disponibles

---

## Contacts & Resources

### Emergency Contacts
- **Admin del Sistema**: _____________________
- **DBA**: _____________________
- **Soporte IT**: _____________________

### Resources
- **Repositorio**: https://github.com/Vekkris76/TimeTracker
- **Documentación**:
  - [UPGRADE_v2.1.0.md](UPGRADE_v2.1.0.md)
  - [SECURITY.md](SECURITY.md)
  - [README.md](README.md)
- **Logs**:
  - PHP: `/var/log/php8.3-fpm.log`
  - Nginx: `/var/log/nginx/error.log`
  - App: `/var/log/timetracker/app.log`

### Useful Commands

```bash
# Ver logs en tiempo real
sudo tail -f /var/log/php8.3-fpm.log

# Verificar conexión BD
mysql -u timetracker_user -p -e "SELECT COUNT(*) FROM timetracker.users;"

# Reiniciar servicios
sudo systemctl restart php8.3-fpm nginx

# Ver usuarios bloqueados por rate limit
mysql -u timetracker_user -p timetracker -e "SELECT * FROM rate_limits WHERE blocked_until > NOW();"

# Desbloquear usuario
mysql -u timetracker_user -p timetracker -e "DELETE FROM rate_limits WHERE identifier='IP_ADDRESS';"
```

---

## Sign-off

### Pre-Deployment
- [ ] Checklist revisado por: _________________ Fecha: _______
- [ ] Backups verificados por: _________________ Fecha: _______
- [ ] Aprobación para deployment: _________________ Fecha: _______

### Post-Deployment
- [ ] Deployment ejecutado por: _________________ Fecha: _______
- [ ] Verificación completada por: _________________ Fecha: _______
- [ ] Sign-off final: _________________ Fecha: _______

---

**Version**: 2.1.0
**Last Updated**: 2026-01-13
**Status**: Ready for Production
