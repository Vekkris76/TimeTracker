# TimeTracker v2.1.0

Sistema de seguimiento de tiempo y proyectos con arquitectura organizada y seguridad empresarial.

## Estructura del Proyecto

```
TimeTracker_v2.0.4_Final/
├── app/                      # Aplicación principal
│   ├── public/              # Archivos accesibles públicamente
│   │   ├── index.html       # Frontend (interfaz de usuario)
│   │   └── api.php          # Backend API (endpoints REST)
│   │
│   ├── config/              # Configuración
│   │   ├── config.php       # Configuración de base de datos
│   │   ├── .env             # Variables de entorno (NO en Git)
│   │   ├── .env.example     # Template de .env
│   │   └── composer.json    # Dependencias PHP
│   │
│   └── src/                 # Código fuente organizado
│       ├── Security/        # Módulos de seguridad
│       │   ├── env-loader.php      # Carga variables .env
│       │   ├── rate-limiter.php    # Anti fuerza bruta
│       │   ├── audit-logger.php    # Sistema de auditoría
│       │   └── validators.php      # Validaciones de negocio
│       │
│       └── Database/        # Scripts de base de datos
│           └── migrate-pins.php    # Migración de PINs (eliminar después)
│
├── deployment/              # Herramientas de despliegue
│   ├── scripts/
│   │   ├── pre-deploy.sh           # Validación pre-despliegue
│   │   ├── deploy-production.sh    # Despliegue automatizado
│   │   └── post-deploy-check.sh    # Verificación post-despliegue
│   └── deploy.bat                  # Herramienta Windows
│
├── docker/                  # Entorno de desarrollo/testing
│   ├── nginx.conf           # Configuración Nginx para Docker
│   ├── init.sql             # Inicialización de BD
│   └── start.sh             # Script de inicio
│
├── docs/                    # Documentación completa
│   ├── README.md                   # Manual general ⭐
│   ├── DEPLOYMENT_GUIDE.md         # Guía de despliegue ⭐
│   ├── DEPLOYMENT_READY.md         # Resumen de deployment ⭐
│   ├── PRODUCTION_CHECKLIST.md     # Checklist producción
│   ├── SECURITY.md                 # Guía de seguridad
│   ├── UPGRADE_v2.1.0.md          # Guía de actualización
│   ├── DOCKER.md                   # Documentación Docker
│   ├── TESTS_RESULTS.md           # Resultados de pruebas
│   ├── RESUMEN_FINAL.md           # Resumen ejecutivo
│   └── CHANGELOG.md               # Registro de cambios
│
├── config/                  # Configuración del servidor
│   └── timetracker.nginx.conf     # Configuración Nginx producción
│
├── docker-compose.yml       # Orquestación Docker
├── Dockerfile               # Imagen Docker personalizada
└── .gitignore              # Archivos excluidos de Git
```

## Inicio Rápido

### 1. Probar Localmente con Docker (5 minutos)

```bash
# Copiar configuración de desarrollo
cp app/config/.env.docker app/config/.env

# Iniciar contenedores
docker-compose up -d

# Acceder a la aplicación
# Web: http://localhost:8090
# PHPMyAdmin: http://localhost:8081
# Login: u0 / admin
```

### 2. Desplegar a Producción (15-30 minutos)

**Método recomendado: Automatizado**

```bash
ssh user@servidor
cd /var/www/timetracker

# 1. Pre-check
sudo bash deployment/scripts/pre-deploy.sh

# 2. Deploy
sudo bash deployment/scripts/deploy-production.sh

# 3. Verificar
sudo bash deployment/scripts/post-deploy-check.sh
```

**Método Windows:**

1. Doble clic en `deployment/deploy.bat`
2. Seguir instrucciones en pantalla

**Ver guía completa:** [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

## Características v2.1.0

### Seguridad
- ✅ Variables de entorno (.env)
- ✅ Hash bcrypt para PINs
- ✅ Rate limiting (anti fuerza bruta)
- ✅ CORS restrictivo
- ✅ Sistema de auditoría completo
- ✅ Validaciones de negocio

### Deployment
- ✅ 3 métodos de despliegue (automatizado, manual, Windows)
- ✅ Scripts de validación (pre/post)
- ✅ Backups automáticos
- ✅ Rollback procedures

### Documentación
- ✅ 11 guías completas
- ✅ Checklists de producción
- ✅ Troubleshooting
- ✅ Guías visuales

## Requisitos

### Producción
- PHP >= 8.1 (recomendado 8.3)
- MySQL 8.0 o MariaDB 10.5+
- Nginx 1.18+ o Apache 2.4+
- Extensiones PHP: pdo, pdo_mysql, json

### Desarrollo
- Docker & Docker Compose
- Git

## Configuración

### Primera vez

1. **Copiar template de configuración:**
   ```bash
   cp app/config/.env.example app/config/.env
   ```

2. **Editar credenciales:**
   ```bash
   nano app/config/.env
   ```

   Configurar:
   - `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`
   - `APP_ENV=production`
   - `APP_DEBUG=false`

3. **Migrar PINs (SOLO primera vez):**
   ```bash
   php app/src/Database/migrate-pins.php
   rm app/src/Database/migrate-pins.php
   ```

4. **Configurar permisos:**
   ```bash
   sudo chown -R www-data:www-data /var/www/timetracker
   sudo chmod 600 app/config/.env
   ```

## Documentación

### Para Sysadmin
1. [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - **Empezar aquí** ⭐
2. [PRODUCTION_CHECKLIST.md](docs/PRODUCTION_CHECKLIST.md) - Checklist completo
3. [SECURITY.md](docs/SECURITY.md) - Guía de seguridad

### Para Project Manager
1. [DEPLOYMENT_READY.md](docs/DEPLOYMENT_READY.md) - Resumen ejecutivo
2. [RESUMEN_FINAL.md](docs/RESUMEN_FINAL.md) - Estadísticas y estado

### Para Desarrolladores
1. [README.md](docs/README.md) - Manual técnico completo
2. [DOCKER.md](docs/DOCKER.md) - Entorno de desarrollo
3. [TESTS_RESULTS.md](docs/TESTS_RESULTS.md) - Resultados de pruebas

## Soporte

- **Repositorio:** https://github.com/Vekkris76/TimeTracker
- **Issues:** https://github.com/Vekkris76/TimeTracker/issues

## Versión

- **Actual:** 2.1.0
- **Fecha:** 2026-01-13
- **Estado:** ✅ Production Ready

## Licencia

Uso interno corporativo - Todos los derechos reservados
