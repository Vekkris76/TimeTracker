# 🚀 TimeTracker v2.1.0 - Visual Deployment Guide

## Quick Reference

| Método | Tiempo | Complejidad | Recomendado Para |
|--------|--------|-------------|------------------|
| **Automatizado** | 15 min | Baja | Todos |
| **Manual** | 30 min | Media | Control detallado |
| **Windows (deploy.bat)** | 10 min | Muy Baja | Usuarios Windows |

---

## 📋 Deployment Flow Diagram

```
┌─────────────────┐
│  Pre-Deployment │
│   Preparation   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Run pre-deploy  │
│    checks       │◄─── STOP if errors
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Create Full   │
│     Backup      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Pull Code     │
│   from GitHub   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Configure .env │◄─── Critical!
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Set Permissions│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Run Migration  │
│  (migrate-pins) │◄─── Once only
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Clean Up Files │
│  (setup.php,etc)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Restart Services│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Run post-check │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Test Application│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Monitor      │
│   (24-48h)      │
└─────────────────┘
```

---

## 🎯 Method 1: Automated Deployment (RECOMMENDED)

### Prerequisites
- [x] SSH access to server
- [x] sudo permissions
- [x] Git installed
- [x] Backup created

### Step-by-Step

#### 1️⃣ Connect to Server
```bash
ssh user@timetracker.resol.dom
cd /var/www/timetracker
```

#### 2️⃣ Run Pre-Deployment Check
```bash
sudo bash pre-deploy.sh
```

**Expected Output:**
```
=================================================
  TimeTracker v2.1.0 - Pre-Deployment Checks
=================================================

[1/10] Checking System Requirements...
✓ PHP 8.3.0 installed
✓ PHP extension: pdo
✓ PHP extension: pdo_mysql
✓ PHP extension: json

[2/10] Checking Web Server...
✓ Nginx 1.18.0 installed
✓ Nginx is running

... (more checks)

=================================================
  Pre-Deployment Check Summary
=================================================

✓ All checks passed! Ready for deployment.
```

**⚠️ STOP HERE** if there are critical errors!

#### 3️⃣ Run Automated Deployment
```bash
sudo bash deploy-production.sh
```

**What it does:**
1. ✅ Creates automatic backup
2. ✅ Pulls latest code
3. ✅ Checks .env configuration
4. ✅ Sets file permissions
5. ✅ Runs PIN migration
6. ✅ Cleans up sensitive files
7. ✅ Restarts services
8. ✅ Runs verification checks

**Expected Output:**
```
=================================================
  TimeTracker v2.1.0 - Production Deployment
=================================================

[1/8] Creating pre-deployment backup...
  ✓ Database backed up
  ✓ Files backed up

[2/8] Pulling latest code from repository...
  ✓ Code updated

[3/8] Checking environment configuration...
  ✓ Environment configuration OK

[4/8] Setting file permissions...
  ✓ Permissions set

[5/8] Running database migrations...
  ✓ PIN migration completed
  ✓ Migration script removed

[6/8] Cleaning up sensitive files...
  ✓ Cleanup complete

[7/8] Restarting services...
  ✓ PHP-FPM restarted
  ✓ Nginx restarted

[8/8] Running post-deployment checks...
  ✓ Nginx is running
  ✓ PHP-FPM is running
  ✓ Database connection OK
  ✓ API is responding

=================================================
  Deployment Complete!
=================================================

✓ TimeTracker v2.1.0 deployed successfully
```

#### 4️⃣ Test Application
```bash
# Test from server
curl http://localhost/api.php?path=all | python3 -m json.tool

# Test from browser
open http://timetracker.resol.dom
# Login with: u0 / admin
```

---

## 🛠️ Method 2: Manual Deployment

### Step-by-Step

#### 1️⃣ Backup
```bash
# Database
mysqldump -u timetracker_user -p timetracker > \
  /var/backups/timetracker/db_$(date +%Y%m%d_%H%M%S).sql

# Files
tar -czf /var/backups/timetracker/files_$(date +%Y%m%d_%H%M%S).tar.gz \
  /var/www/timetracker/
```

#### 2️⃣ Pull Code
```bash
cd /var/www/timetracker
git fetch origin
git pull origin main
```

#### 3️⃣ Configure .env
```bash
# Create if doesn't exist
cp .env.example .env
nano .env
```

**Edit these values:**
```env
DB_HOST=localhost
DB_NAME=timetracker
DB_USER=timetracker_user
DB_PASS=YOUR_REAL_PASSWORD_HERE    # ← Change this!
DB_CHARSET=utf8mb4

APP_ENV=production                  # ← Must be "production"
APP_DEBUG=false                     # ← Must be "false"
APP_DOMAIN=timetracker.resol.dom

RATE_LIMIT_ATTEMPTS=5
RATE_LIMIT_MINUTES=15
```

#### 4️⃣ Set Permissions
```bash
sudo chown -R www-data:www-data /var/www/timetracker
sudo chmod -R 755 /var/www/timetracker
sudo chmod 600 /var/www/timetracker/.env
```

#### 5️⃣ Run Migration (ONCE)
```bash
cd /var/www/timetracker
php migrate-pins.php
```

**Expected output:**
```json
{
  "success": true,
  "migrated": 5,
  "skipped": 0,
  "total": 5,
  "message": "Migración completada. 5 PINs hasheados, 0 ya estaban hasheados."
}
```

Then remove the script:
```bash
rm migrate-pins.php
```

#### 6️⃣ Clean Up
```bash
rm -f setup.php test_login.php
```

#### 7️⃣ Restart Services
```bash
sudo systemctl restart php8.3-fpm
sudo nginx -t && sudo systemctl restart nginx
```

#### 8️⃣ Verify
```bash
sudo bash post-deploy-check.sh
```

---

## 💻 Method 3: Windows Deployment (deploy.bat)

### Step-by-Step

#### 1️⃣ Open deploy.bat
```cmd
Double-click: deploy.bat
```

#### 2️⃣ Select Option 3: Pre-Deployment Check
```
=========================================================
  TimeTracker v2.1.0 - Gestion de Despliegue
=========================================================

  1. Subir archivos al servidor (DEPLOY)
  2. Descargar archivos del servidor (BACKUP LOCAL)
  3. Ejecutar script de pre-deployment
  4. Ejecutar script de post-deployment
  5. Salir
=========================================================

Selecciona una opcion (1-5): 3
```

#### 3️⃣ Review Output - STOP if Errors

#### 4️⃣ Select Option 1: Deploy
```
Selecciona una opcion (1-5): 1
```

**Confirm when prompted:**
```
Continuar? (S/N): S
```

#### 5️⃣ Follow Post-Deployment Instructions
The script will show:
```
PASOS SIGUIENTES (IMPORTANTE):

1. Conectar por SSH al servidor:
   ssh miguel@192.168.11.39

2. Ir al directorio:
   cd /var/www/timetracker

3. Crear archivo .env (si no existe):
   cp .env.example .env
   nano .env

4. Ejecutar migración de PINs (SOLO UNA VEZ):
   php migrate-pins.php

5. Eliminar script de migración:
   rm migrate-pins.php

6. Verificar deployment:
   sudo bash post-deploy-check.sh

7. Reiniciar servicios:
   sudo systemctl restart php8.3-fpm nginx
```

#### 6️⃣ Return to Menu - Option 4: Post-Check
```
Selecciona una opcion (1-5): 4
```

---

## ✅ Verification Checklist

### Immediate Checks (0-5 min)

- [ ] **Services Running**
  ```bash
  sudo systemctl status nginx
  sudo systemctl status php8.3-fpm
  sudo systemctl status mysql
  ```

- [ ] **API Responding**
  ```bash
  curl http://localhost/api.php?path=all
  ```

- [ ] **No Errors in Logs**
  ```bash
  tail -50 /var/log/php8.3-fpm.log
  tail -50 /var/log/nginx/error.log
  ```

### Functional Tests (5-10 min)

- [ ] **Login Works**
  - Open: http://timetracker.resol.dom
  - Login with: u0 / admin
  - Should succeed

- [ ] **Create Entry**
  - Navigate to Timesheet
  - Add hours for today
  - Save
  - Should work without errors

- [ ] **View Dashboard** (Manager/Admin)
  - Click Dashboard tab
  - Should load data and charts

### Security Tests (5 min)

- [ ] **Validations Work**
  - Try entering negative hours → Should fail
  - Try entering > 24 hours → Should fail
  - Try entering future date → Should fail

- [ ] **Rate Limiting Works**
  - Try 6 failed logins → Should block

- [ ] **Audit Log Working**
  ```sql
  SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 10;
  ```

---

## 🔥 Troubleshooting

### Issue: "Database connection failed"

**Solution:**
```bash
# Check .env file
cat /var/www/timetracker/.env

# Test connection manually
mysql -u timetracker_user -p timetracker -e "SELECT 1;"

# Verify config.php loads .env
php -r "require 'config.php'; echo 'OK';"
```

### Issue: "403 Forbidden"

**Solution:**
```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/timetracker
sudo chmod -R 755 /var/www/timetracker

# Check Nginx config
sudo nginx -t
```

### Issue: "502 Bad Gateway"

**Solution:**
```bash
# Check PHP-FPM
sudo systemctl status php8.3-fpm
sudo systemctl restart php8.3-fpm

# Check PHP-FPM logs
sudo tail -50 /var/log/php8.3-fpm.log
```

### Issue: "Credenciales incorrectas" after migration

**Solution:**
```bash
# Check if PINs are hashed
mysql -u timetracker_user -p timetracker \
  -e "SELECT id, name, LEFT(pin, 10) FROM users;"

# Should show: $2y$10$...

# If not hashed, run migration again
php migrate-pins.php
```

### Issue: "User blocked" (rate limit)

**Solution:**
```sql
-- View blocked users
SELECT * FROM rate_limits WHERE blocked_until > NOW();

-- Unblock specific IP
DELETE FROM rate_limits WHERE identifier = 'IP_ADDRESS';

-- Clear all blocks
TRUNCATE TABLE rate_limits;
```

---

## 📊 Monitoring Dashboard

### Day 1 - Active Monitoring (Every 2-4 hours)

```bash
# Error logs
tail -100 /var/log/php8.3-fpm.log | grep -i error

# Audit log
mysql -u user -p timetracker -e "
  SELECT user_id, action, COUNT(*) as count
  FROM audit_log
  WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
  GROUP BY user_id, action
  ORDER BY count DESC;"

# Rate limits
mysql -u user -p timetracker -e "
  SELECT identifier, action, attempts, blocked_until
  FROM rate_limits
  WHERE attempts > 0 OR blocked_until > NOW();"
```

### Day 2-3 - Passive Monitoring (1-2 times/day)

```bash
# Quick health check
curl -s http://localhost/api.php?path=all | python3 -m json.tool | head

# Service status
sudo systemctl is-active nginx php8.3-fpm mysql
```

---

## 📞 Emergency Contacts

| Role | Contact | When to Call |
|------|---------|--------------|
| **Sysadmin** | _____________ | Server/network issues |
| **DBA** | _____________ | Database problems |
| **IT Support** | _____________ | General issues |

---

## 🎯 Success Criteria

Deployment is successful when:

1. ✅ All post-deployment checks pass
2. ✅ Users can login
3. ✅ No errors in logs
4. ✅ API responds in < 500ms
5. ✅ Rate limiting works
6. ✅ Audit log records actions
7. ✅ Validations prevent bad data
8. ✅ No user complaints after 24h

---

## 📚 Additional Resources

- **Full Checklist**: [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)
- **Security Guide**: [SECURITY.md](SECURITY.md)
- **Upgrade Details**: [UPGRADE_v2.1.0.md](UPGRADE_v2.1.0.md)
- **General Manual**: [README.md](README.md)
- **Test Results**: [TESTS_RESULTS.md](TESTS_RESULTS.md)

---

**Version**: 2.1.0
**Last Updated**: 2026-01-13
**Estimated Deployment Time**: 15-30 minutes
**Difficulty**: Easy (Automated) / Medium (Manual)
