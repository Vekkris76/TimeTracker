# TimeTracker v2.0.4 - Manual de Instalación y Uso

## 📋 Índice

1. [Descripción General](#descripción-general)
2. [Requisitos del Sistema](#requisitos-del-sistema)
3. [Instalación en Servidor](#instalación-en-servidor)
4. [Configuración Inicial](#configuración-inicial)
5. [Despliegue desde Windows](#despliegue-desde-windows)
6. [Uso de la Aplicación](#uso-de-la-aplicación)
7. [Gestión de Backups](#gestión-de-backups)
8. [Solución de Problemas](#solución-de-problemas)
9. [Seguridad](#seguridad)
10. [Changelog](#changelog)

---

## 📖 Descripción General

**TimeTracker v2.0.4** es una aplicación web de seguimiento de tiempo diseñada para uso corporativo interno. Permite a los usuarios registrar horas trabajadas en diferentes proyectos y tareas, con funcionalidades de reporting y análisis para managers y administradores.

### Características Principales

- ✅ Timesheet semanal intuitivo
- ✅ Gestión de empresas, departamentos, proyectos y tareas
- ✅ Dashboard con gráficos y estadísticas
- ✅ 3 niveles de permisos (User, Manager, Admin)
- ✅ Exportación a Excel
- ✅ Diseño responsive
- ✅ Sin dependencias de frameworks (JavaScript vanilla)

---

## 🖥️ Requisitos del Sistema

### Servidor de Producción

- **Sistema Operativo**: Linux (Ubuntu 20.04+ / Debian 10+ recomendado)
- **Servidor Web**: Nginx 1.18+
- **PHP**: 8.1, 8.2 o 8.3 con extensiones:
  - php-fpm
  - php-mysql (PDO_MySQL)
  - php-json
- **Base de Datos**: MySQL 5.7+ o MariaDB 10.2+
- **SSL/TLS**: Certificado (opcional pero recomendado)

### Estación de Desarrollo (Windows)

Para usar el script de despliegue `deploy.bat`:
- **Sistema Operativo**: Windows 10/11
- **PuTTY Tools**: [Descargar aquí](https://www.putty.org/)
  - `pscp.exe` (para copiar archivos)
  - `plink.exe` (para comandos SSH)

---

## 🚀 Instalación en Servidor

### Paso 1: Preparar el Entorno

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Nginx
sudo apt install nginx -y

# Instalar PHP y extensiones
sudo apt install php8.3-fpm php8.3-mysql php8.3-json -y

# Instalar MySQL/MariaDB
sudo apt install mariadb-server -y
```

### Paso 2: Configurar la Base de Datos

```bash
# Conectar a MySQL
sudo mysql

# Dentro de MySQL:
CREATE DATABASE timetracker CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'timetracker_user'@'localhost' IDENTIFIED BY 'Tm135Tk579$';

GRANT ALL PRIVILEGES ON timetracker.* TO 'timetracker_user'@'localhost';

FLUSH PRIVILEGES;

EXIT;
```

### Paso 3: Crear Directorio de la Aplicación

```bash
# Crear directorio
sudo mkdir -p /var/www/timetracker

# Establecer permisos
sudo chown -R www-data:www-data /var/www/timetracker
sudo chmod -R 755 /var/www/timetracker
```

### Paso 4: Configurar Nginx

```bash
# Copiar configuración
sudo cp /var/www/timetracker/timetracker.nginx.conf /etc/nginx/sites-available/timetracker

# Crear enlace simbólico
sudo ln -s /etc/nginx/sites-available/timetracker /etc/nginx/sites-enabled/

# Eliminar configuración default (opcional)
sudo rm /etc/nginx/sites-enabled/default

# Probar configuración
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

### Paso 5: Configurar PHP-FPM

```bash
# Editar configuración de PHP-FPM (si es necesario)
sudo nano /etc/php/8.3/fpm/php.ini

# Ajustar estos valores:
upload_max_filesize = 20M
post_max_size = 20M
max_execution_time = 300

# Reiniciar PHP-FPM
sudo systemctl restart php8.3-fpm
```

---

## ⚙️ Configuración Inicial

### Paso 1: Desplegar Archivos

Usar el script `deploy.bat` desde Windows (ver sección siguiente) o copiar manualmente:

```bash
# Copiar archivos al servidor
scp index.html miguel@192.168.11.39:/var/www/timetracker/
scp api.php miguel@192.168.11.39:/var/www/timetracker/
scp config.php miguel@192.168.11.39:/var/www/timetracker/
scp setup.php miguel@192.168.11.39:/var/www/timetracker/
```

### Paso 2: Ejecutar Setup

1. Abrir navegador: `http://timetracker.resol.dom/setup.php`
2. El script creará automáticamente:
   - 8 tablas en la base de datos
   - 9 tareas predefinidas
   - Usuario administrador por defecto
3. **IMPORTANTE**: Eliminar `setup.php` después de la instalación

```bash
sudo rm /var/www/timetracker/setup.php
```

### Paso 3: Cambiar Contraseña de Admin

1. Acceder con credenciales por defecto:
   - **Usuario**: `u0`
   - **PIN**: `admin`
2. Hacer clic en el icono de usuario → "Cambiar contraseña"
3. Establecer un PIN seguro

---

## 💻 Despliegue desde Windows

### Instalación de PuTTY Tools

1. Descargar PuTTY desde: https://www.putty.org/
2. Extraer `pscp.exe` y `plink.exe`
3. Copiar ambos archivos a:
   - `C:\Projects\TimeTracker_v2.0.4_Final\` (carpeta del proyecto)
   - O agregar al PATH de Windows

### Uso del Script de Despliegue

#### Ejecutar deploy.bat

```batch
# Hacer doble clic en:
deploy.bat
```

#### Menú de Opciones

```
=========================================================
  TimeTracker v2.0.4 - Gestion de Despliegue
=========================================================

  1. Subir archivos al servidor (DEPLOY)
  2. Descargar archivos del servidor (BACKUP LOCAL)
  3. Salir
=========================================================
```

### Opción 1: Subir Archivos (Deploy)

**Qué hace:**
- Crea backup automático en el servidor (`/var/www/timetracker/backups/`)
- Sube todos los archivos al servidor
- Configura credenciales de producción en `config.php`
- Establece permisos correctos

**Cuándo usar:**
- Después de hacer cambios en el código local
- Para actualizar la aplicación en producción
- Para desplegar por primera vez

**Proceso:**
1. Seleccionar opción `1`
2. Confirmar con `S`
3. Esperar confirmación de cada archivo
4. Volver al menú o salir

### Opción 2: Descargar Archivos (Backup Local)

**Qué hace:**
- Descarga todos los archivos del servidor
- Crea carpeta local: `backup_AAAAMMDD_HHMMSS`
- NO sobrescribe archivos locales actuales

**Cuándo usar:**
- Antes de hacer cambios importantes
- Para crear respaldo local
- Para comparar versiones (local vs servidor)

**Proceso:**
1. Seleccionar opción `2`
2. Confirmar con `S`
3. Esperar descarga de cada archivo
4. Ver carpeta creada con timestamp

### Configuración del Script

Editar `deploy.bat` si cambias credenciales o servidor:

```batch
set SERVER=192.168.11.39
set USER=miguel
set PASSWORD=Mg137Pz248$
set REMOTE_PATH=/var/www/timetracker
```

---

## 👥 Uso de la Aplicación

### Acceso a la Aplicación

URL: `http://timetracker.resol.dom/`

### Roles de Usuario

| Rol | Permisos |
|-----|----------|
| **Admin** | Acceso total: gestión de empresas, departamentos, proyectos, tareas, usuarios |
| **Manager** | Ve dashboard de su departamento, gestiona proyectos y timesheet |
| **User** | Registra sus horas, ve sus estadísticas personales |

### Usuario Administrador por Defecto

```
Usuario: u0
PIN: admin
```

⚠️ **Cambiar inmediatamente después de la instalación**

### Pantallas Principales

#### 1. Timesheet (Todos los usuarios)
- Vista semanal de lunes a viernes
- Selección de proyecto y tarea por fila
- Entrada de horas por día
- Totales por día y por fila
- Copiar estructura de semana anterior/siguiente
- Eliminar filas

#### 2. Mis Estadísticas (Todos los usuarios)
- Gráfico de barras mensual
- Distribución por proyecto y tarea
- Filtros de fecha

#### 3. Dashboard (Manager/Admin)
- Estadísticas agregadas del equipo
- Filtros por empresa, departamento, usuario, proyecto
- Gráficos de distribución
- Tarjetas de resumen por usuario

#### 4. Todas las Entradas (Manager/Admin)
- Lista completa de registros de tiempo
- Filtros avanzados
- Exportación a Excel

#### 5. Gestión de Datos (Admin)

**Empresas:**
- Código y nombre de empresa
- Asociación con proyectos

**Departamentos:**
- Código y nombre de departamento
- Asociación con usuarios

**Proyectos:**
- Código, nombre, cliente
- Estado (activo/inactivo)
- Empresa asociada

**Tareas:**
- 9 tareas predefinidas
- Posibilidad de añadir más
- Ordenamiento personalizado

**Usuarios:**
- Nombre, PIN, perfil, rol
- Asignación de departamento y empresa
- Proyectos asignados
- Departamentos gestionados (para managers)

#### 6. Configuración (Admin)
- Exportar datos completos a Excel
- Importar datos desde JSON

---

## 💾 Gestión de Backups

### Backups Automáticos en Servidor

Cada vez que ejecutas `deploy.bat` opción 1:
```
/var/www/timetracker/backups/backup_AAAAMMDD_HHMMSS.tar.gz
```

### Backups Manuales en Servidor

```bash
# Conectar por SSH
ssh miguel@192.168.11.39

# Crear backup manual
cd /var/www/timetracker
tar -czf backups/backup_manual_$(date +%Y%m%d_%H%M%S).tar.gz \
    index.html api.php config.php CHANGELOG.md

# Backup de base de datos
mysqldump -u timetracker_user -p timetracker > \
    backups/db_backup_$(date +%Y%m%d_%H%M%S).sql
```

### Backups Locales desde Windows

Usar `deploy.bat` opción 2:
```
C:\Projects\TimeTracker_v2.0.4_Final\backup_AAAAMMDD_HHMMSS\
```

### Restaurar desde Backup

#### Restaurar archivos:
```bash
cd /var/www/timetracker
tar -xzf backups/backup_AAAAMMDD_HHMMSS.tar.gz
```

#### Restaurar base de datos:
```bash
mysql -u timetracker_user -p timetracker < backups/db_backup_AAAAMMDD_HHMMSS.sql
```

---

## 🔧 Solución de Problemas

### Error: "No se encuentra pscp.exe"

**Solución:**
1. Descargar PuTTY tools: https://www.putty.org/
2. Copiar `pscp.exe` y `plink.exe` a la carpeta del proyecto
3. O agregar al PATH de Windows

### Error: "Connection refused" al ejecutar deploy.bat

**Posibles causas:**
1. Servidor apagado o inaccesible
2. Credenciales incorrectas
3. Firewall bloqueando conexión

**Solución:**
```bash
# Verificar que el servidor esté accesible
ping 192.168.11.39

# Probar conexión SSH manual
ssh miguel@192.168.11.39
```

### Error: "Database connection failed"

**Solución:**
1. Verificar credenciales en `config.php`:
```php
$host = 'localhost';
$db = 'timetracker';
$user = 'timetracker_user';
$pass = 'Tm135Tk579$';
```

2. Verificar que MySQL esté corriendo:
```bash
sudo systemctl status mysql
```

3. Verificar permisos de usuario:
```sql
SHOW GRANTS FOR 'timetracker_user'@'localhost';
```

### Error 404 al acceder a la aplicación

**Solución:**
1. Verificar configuración de Nginx:
```bash
sudo nginx -t
```

2. Verificar que los archivos existan:
```bash
ls -la /var/www/timetracker/
```

3. Verificar permisos:
```bash
sudo chown -R www-data:www-data /var/www/timetracker/
sudo chmod -R 755 /var/www/timetracker/
```

### Error 502 Bad Gateway

**Solución:**
1. Verificar que PHP-FPM esté corriendo:
```bash
sudo systemctl status php8.3-fpm
```

2. Reiniciar PHP-FPM:
```bash
sudo systemctl restart php8.3-fpm
```

3. Verificar logs:
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/php8.3-fpm.log
```

### La aplicación no carga datos

**Solución:**
1. Abrir consola del navegador (F12)
2. Ver errores en la pestaña "Console"
3. Verificar llamadas API en "Network"
4. Comprobar que `api.php` responda:
```
http://timetracker.resol.dom/api.php?path=all
```

### Problemas con filtros en Dashboard

**Versión 2.0.4.1 corrige este problema**

Si tienes versión anterior:
- Descargar archivos actualizados
- Ejecutar `deploy.bat` opción 1

---

## 🔒 Seguridad

### Recomendaciones de Seguridad

#### 1. Cambiar Credenciales por Defecto

```sql
# Cambiar password del usuario de BD
ALTER USER 'timetracker_user'@'localhost' IDENTIFIED BY 'NuevaPasswordSegura!';
```

Actualizar `config.php` en consecuencia.

#### 2. Eliminar setup.php

```bash
sudo rm /var/www/timetracker/setup.php
```

#### 3. Configurar HTTPS

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtener certificado SSL
sudo certbot --nginx -d timetracker.resol.dom
```

#### 4. Configurar Firewall

```bash
# Permitir solo SSH, HTTP y HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

#### 5. Limitar Acceso por IP (Opcional)

Editar `/etc/nginx/sites-available/timetracker`:

```nginx
location / {
    allow 192.168.11.0/24;  # Red interna
    deny all;
}
```

#### 6. Proteger archivos sensibles

```bash
# Permisos restrictivos para config.php
sudo chmod 640 /var/www/timetracker/config.php
```

#### 7. Backups Regulares

Configurar cron para backups automáticos:

```bash
# Editar crontab
crontab -e

# Agregar backup diario a las 2 AM
0 2 * * * mysqldump -u timetracker_user -pTm135Tk579$ timetracker > /var/www/timetracker/backups/db_backup_$(date +\%Y\%m\%d).sql
```

### Seguridad a Nivel de Aplicación

- ✅ Prepared statements (previene SQL injection)
- ✅ Validación de inputs en backend
- ✅ Control de acceso por roles
- ✅ Sin almacenamiento de sesiones del lado del servidor (stateless)
- ⚠️ PINs en texto plano (solo para uso interno en intranet)

**Nota**: Para uso externo, implementar hashing de passwords con `password_hash()` de PHP.

---

## 📝 Changelog

Ver archivo [CHANGELOG.md](CHANGELOG.md) para lista detallada de cambios.

### Versión 2.0.4.1 (2026-01-13)

**Correcciones principales:**
- ✅ Filtros del dashboard corregidos
- ✅ Parsing de fechas en gráficos mejorado
- ✅ Generación de IDs únicos
- ✅ Validaciones completas en API
- ✅ Transacciones en operaciones multi-tabla
- ✅ Verificación de existencia en actualizaciones

**Total: 20 errores corregidos**

---

## 📞 Soporte y Contacto

### Estructura de Archivos

```
TimeTracker_v2.0.4_Final/
├── index.html                  # Frontend completo
├── api.php                     # Backend REST API
├── config.php                  # Configuración de BD
├── setup.php                   # Script de instalación
├── timetracker.nginx.conf      # Configuración Nginx
├── deploy.bat                  # Script de despliegue Windows
├── CHANGELOG.md                # Registro de cambios
├── README.md                   # Este archivo
└── INSTRUCCIONES.txt           # Instrucciones originales
```

### Logs del Sistema

- **Nginx**: `/var/log/nginx/error.log`
- **PHP-FPM**: `/var/log/php8.3-fpm.log`
- **MySQL**: `/var/log/mysql/error.log`

### Comandos Útiles

```bash
# Ver logs en tiempo real
sudo tail -f /var/log/nginx/error.log

# Reiniciar servicios
sudo systemctl restart nginx
sudo systemctl restart php8.3-fpm
sudo systemctl restart mysql

# Ver estado de servicios
sudo systemctl status nginx
sudo systemctl status php8.3-fpm
sudo systemctl status mysql

# Verificar conectividad de BD
mysql -u timetracker_user -p -e "SHOW DATABASES;"
```

---

## 📄 Licencia

Aplicación de uso interno corporativo.

---

## 🎯 Próximas Mejoras Sugeridas

- [ ] Exportación a PDF
- [ ] Logs de actividad de usuarios
- [ ] Notificaciones por email
- [ ] API de integración con sistemas externos
- [ ] App móvil
- [ ] Modo offline

---

**TimeTracker v2.0.4** - Sistema de Seguimiento de Tiempo
© 2026 - Todos los derechos reservados
