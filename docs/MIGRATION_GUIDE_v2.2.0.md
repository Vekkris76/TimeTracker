# Guía de Migración a v2.2.0 - Estructura Reorganizada

## Cambios en v2.2.0

Esta versión reorganiza completamente la estructura de archivos del proyecto para una mejor mantenibilidad y profesionalismo.

### Estructura Anterior (v2.1.0)
```
TimeTracker_v2.0.4_Final/
├── index.html
├── api.php
├── config.php
├── env-loader.php
├── rate-limiter.php
├── audit-logger.php
├── validators.php
├── migrate-pins.php
├── *.md (docs)
└── *.sh (scripts)
```

### Estructura Nueva (v2.2.0)
```
TimeTracker_v2.0.4_Final/
├── app/
│   ├── public/          # Frontend y API (NUEVO: root de Nginx)
│   ├── config/          # Configuración
│   └── src/             # Código fuente organizado
├── deployment/          # Scripts de despliegue
├── docs/                # Documentación
├── docker/              # Entorno Docker
└── config/              # Config del servidor
```

---

## Migración Paso a Paso

### Pre-requisitos
- [ ] Backup completo de base de datos y archivos
- [ ] Ventana de mantenimiento programada
- [ ] Acceso SSH al servidor

### Paso 1: Backup (5 min)

```bash
# Conectar al servidor
ssh user@timetracker.resol.dom
cd /var/www/timetracker

# Backup base de datos
source .env
mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > ~/backup_timetracker_$(date +%Y%m%d_%H%M%S).sql

# Backup archivos
tar -czf ~/backup_timetracker_files_$(date +%Y%m%d_%H%M%S).tar.gz .
```

### Paso 2: Actualizar Código (2 min)

```bash
cd /var/www/timetracker
git fetch origin
git pull origin main
```

**IMPORTANTE:** Después del pull, la estructura de archivos habrá cambiado completamente.

### Paso 3: Migrar Configuración .env (3 min)

```bash
# Mover .env a la nueva ubicación
mv .env app/config/.env 2>/dev/null || echo ".env ya está en la nueva ubicación"

# Verificar que existe
cat app/config/.env
```

### Paso 4: Actualizar Configuración Nginx (5 min)

**Cambio crítico:** El document root debe apuntar a `app/public/` en lugar de la raíz.

#### Opción A: Usar archivo incluido

```bash
# Copiar configuración incluida
sudo cp config/timetracker.nginx.conf /etc/nginx/sites-available/timetracker

# Editar y actualizar paths
sudo nano /etc/nginx/sites-available/timetracker
```

Cambiar:
```nginx
root /var/www/timetracker;
```

Por:
```nginx
root /var/www/timetracker/app/public;
```

#### Opción B: Actualizar configuración existente

```bash
# Editar configuración actual
sudo nano /etc/nginx/sites-available/timetracker
```

**Cambios necesarios:**

1. **Document Root:**
   ```nginx
   # ANTES
   root /var/www/timetracker;

   # DESPUÉS
   root /var/www/timetracker/app/public;
   ```

2. **Bloquear accesos no deseados:**
   ```nginx
   # Denegar acceso a directorios internos
   location ~ ^/(app/config|app/src|deployment|docs) {
       deny all;
       return 404;
   }
   ```

**Configuración completa recomendada:**

```nginx
server {
    listen 80;
    server_name timetracker.resol.dom;
    root /var/www/timetracker/app/public;
    index index.html index.php;

    # Logs
    access_log /var/log/nginx/timetracker_access.log;
    error_log /var/log/nginx/timetracker_error.log;

    # Desactivar listado de directorios
    autoindex off;

    # Denegar acceso a directorios internos
    location ~ ^/(app/config|app/src|deployment|docs|config|docker) {
        deny all;
        return 404;
    }

    # Servir archivos estáticos y PHP
    location / {
        try_files $uri $uri/ =404;
    }

    # PHP-FPM
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    # Denegar archivos sensibles
    location ~ /\.(env|git|htaccess) {
        deny all;
        return 404;
    }

    location ~ \.(log|md|txt|sql|json|lock|sh|bat)$ {
        deny all;
        return 404;
    }

    # Cache para estáticos
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Paso 5: Verificar y Reiniciar Nginx (2 min)

```bash
# Verificar sintaxis
sudo nginx -t

# Si OK, reiniciar
sudo systemctl restart nginx
sudo systemctl status nginx
```

### Paso 6: Actualizar Permisos (2 min)

```bash
cd /var/www/timetracker

# Permisos generales
sudo chown -R www-data:www-data .
sudo chmod -R 755 .

# Permisos específicos para .env
sudo chmod 600 app/config/.env
```

### Paso 7: Verificar Aplicación (5 min)

```bash
# Probar API
curl http://localhost/api.php?path=all

# Debería devolver JSON con companies, depts, projects, etc.
```

**Verificar desde navegador:**
1. Abrir: http://timetracker.resol.dom
2. Login con usuario de prueba
3. Verificar que todo funciona

### Paso 8: Verificar Logs (2 min)

```bash
# Logs de Nginx
sudo tail -50 /var/log/nginx/error.log

# Logs de PHP
sudo tail -50 /var/log/php8.3-fpm.log

# No debería haber errores relacionados con rutas
```

---

## Troubleshooting

### Error: 404 Not Found

**Problema:** Nginx no encuentra index.html o api.php

**Solución:**
```bash
# Verificar document root
grep -r "root" /etc/nginx/sites-available/timetracker

# Debe mostrar: root /var/www/timetracker/app/public;

# Verificar que los archivos existen
ls -la /var/www/timetracker/app/public/
# Debe mostrar: index.html, api.php
```

### Error: 403 Forbidden

**Problema:** Permisos incorrectos

**Solución:**
```bash
sudo chown -R www-data:www-data /var/www/timetracker
sudo chmod -R 755 /var/www/timetracker
sudo chmod 600 /var/www/timetracker/app/config/.env
```

### Error: "Database connection failed"

**Problema:** No encuentra el archivo .env

**Solución:**
```bash
# Verificar que .env existe en la nueva ubicación
ls -la /var/www/timetracker/app/config/.env

# Si no existe, copiarlo
cp /var/www/timetracker/app/config/.env.example /var/www/timetracker/app/config/.env

# Editar con credenciales correctas
nano /var/www/timetracker/app/config/.env
```

### Error: require_once failed

**Problema:** Rutas antiguas en código personalizado

**Solución:**
Si modificaste código, actualiza las rutas:
```php
// ANTES
require_once 'config.php';
require_once 'env-loader.php';

// DESPUÉS
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../src/Security/env-loader.php';
```

---

## Rollback (Si algo sale mal)

### Opción 1: Rollback de Git

```bash
cd /var/www/timetracker
git log --oneline -5  # Ver últimos commits
git reset --hard <commit_anterior>  # Volver al commit anterior a v2.2.0
```

### Opción 2: Restaurar Backup

```bash
# Restaurar archivos
cd /var/www/timetracker
rm -rf *
tar -xzf ~/backup_timetracker_files_TIMESTAMP.tar.gz

# Restaurar BD
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < ~/backup_timetracker_TIMESTAMP.sql

# Restaurar configuración Nginx anterior
sudo nano /etc/nginx/sites-available/timetracker
# Cambiar root de vuelta a: root /var/www/timetracker;

sudo nginx -t
sudo systemctl restart nginx
```

---

## Post-Migración

### Actualizar Scripts de Deployment Local

Si usas `deployment/deploy.bat` desde Windows, la nueva versión ya está actualizada. Solo asegúrate de:

1. Tener la última versión del repo localmente
2. El script automáticamente sube la estructura correcta

### Actualizar Scripts de Monitoreo

Si tienes scripts de monitoreo, actualiza las rutas:

```bash
# ANTES
curl http://localhost/api.php?path=all

# DESPUÉS (sin cambios, Nginx redirige correctamente)
curl http://localhost/api.php?path=all
# O explícitamente:
curl http://localhost/app/public/api.php?path=all
```

### Verificar Backups Automáticos

Si tienes backups automáticos configurados, verifica que incluyan las nuevas rutas:

```bash
# Asegúrate de incluir:
- app/config/.env
- app/public/
- app/src/
```

---

## Checklist Final

- [ ] Nginx apunta a `app/public/`
- [ ] .env está en `app/config/.env`
- [ ] Login funciona correctamente
- [ ] API responde correctamente
- [ ] No hay errores en logs
- [ ] Permisos configurados correctamente
- [ ] Backups funcionando
- [ ] Scripts de deployment actualizados

---

## Contacto

- **Repositorio:** https://github.com/Vekkris76/TimeTracker
- **Issues:** https://github.com/Vekkris76/TimeTracker/issues

---

**Versión:** 2.2.0
**Fecha:** 2026-01-13
**Tiempo estimado de migración:** 20-30 minutos
**Downtime requerido:** 5-10 minutos
