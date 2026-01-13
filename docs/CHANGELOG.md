# TimeTracker v2.0.4 - Registro de Cambios

## [2.0.4.1] - 2026-01-13

### Correcciones Críticas

#### Frontend (index.html)

##### 🐛 Filtros del Dashboard
- **Problema**: Los filtros vacíos mostraban todos los registros en lugar de ninguno
- **Archivos**: `index.html` líneas 673-676
- **Solución**: Agregada validación `length > 0` a todos los filtros antes de aplicarlos
- **Impacto**: Los filtros de empresa, departamento, usuario y proyecto ahora funcionan correctamente cuando no hay selecciones

##### 🐛 Parsing de Fechas en Gráficos
- **Problema**: `new Date(e.date)` causaba problemas de timezone que desplazaban las fechas
- **Archivos**: `index.html` líneas 624-625, 726-727
- **Solución**: Implementado parsing explícito: `e.date.split('-')` → `new Date(year, month-1, day)`
- **Impacto**: Los gráficos mensuales ahora agrupan correctamente las entradas por mes sin desplazamientos

##### 🐛 Generación de IDs Únicos
- **Problema**: `Date.now()` podía generar IDs duplicados si se creaban filas muy rápidamente
- **Archivos**: `index.html` líneas 503, 540, 562
- **Solución**: Agregado sufijo aleatorio: `'e'+Date.now()+Math.random().toString(36).substr(2,5)`
- **Impacto**: Elimina race conditions al crear múltiples entradas rápidamente

##### 🐛 Manejo de Errores en copyWeek()
- **Problema**: Sin try-catch, los errores de API dejaban el estado inconsistente
- **Archivos**: `index.html` líneas 541-549, 563-571
- **Solución**: Agregados bloques try-catch con manejo de errores y mensajes al usuario
- **Impacto**: Los errores ahora se manejan gracefully y se informa al usuario correctamente

---

#### Backend (api.php)

##### ✅ Validación de Campos Requeridos
- **Endpoints afectados**: Companies, Depts, Projects (POST/PUT)
- **Archivos**: `api.php` líneas 34-37, 43-46, 75-78, 84-87, 116-119, 132-135
- **Solución**: Agregada validación `empty()` para todos los campos obligatorios
- **Respuesta**: HTTP 400 con mensaje `{'error': 'Faltan campos requeridos'}`
- **Impacto**: Previene la inserción de datos inválidos en la base de datos

##### ✅ Verificación de Existencia en PUT
- **Endpoints afectados**: Companies, Depts, Projects, Users, Entries (PUT)
- **Archivos**: `api.php` líneas 50-55, 91-96, 146-151, 272-277, 353-358
- **Solución**: Verificación de `rowCount() === 0` después de UPDATE
- **Respuesta**: HTTP 404 con mensaje específico por entidad
- **Impacto**: El frontend ahora recibe feedback correcto cuando se intenta actualizar recursos inexistentes

##### ✅ Estandarización de IDs en DELETE
- **Endpoints afectados**: Todos los DELETE
- **Archivos**: `api.php` líneas 57-62, 98-103, 153-158, 242-247, 260-265
- **Solución**: Solo se acepta ID desde `$input['id']` con validación obligatoria
- **Respuesta**: HTTP 400 si falta el ID
- **Impacto**: API más consistente y predecible

##### ✅ Transacciones en Operaciones Multi-Tabla
- **Endpoints afectados**: Users (POST/PUT)
- **Archivos**: `api.php` líneas 217-250, 258-300
- **Solución**: Implementadas transacciones con `beginTransaction()`, `commit()` y `rollBack()`
- **Impacto**: Garantiza integridad de datos. Si falla cualquier operación, se revierten todos los cambios

##### ✅ Validación de Rango de Horas
- **Endpoint afectado**: Entries (PUT)
- **Archivos**: `api.php` líneas 345-350
- **Solución**: Validación `0 <= hours <= 24` antes de actualizar
- **Respuesta**: HTTP 400 con mensaje `{'error': 'Las horas deben estar entre 0 y 24'}`
- **Impacto**: Previene datos absurdos en el sistema

##### ✅ Validación de Usuarios
- **Endpoints afectados**: Users (POST/PUT)
- **Archivos**: `api.php` líneas 211-215, 252-256
- **Solución**: Validación de campos obligatorios (id, name, pin)
- **Impacto**: Previene creación de usuarios sin datos esenciales

---

### Resumen Estadístico

| Categoría | Errores Corregidos |
|-----------|-------------------|
| Lógica de Filtros | 4 |
| Fechas/Timezone | 2 |
| Generación de IDs | 3 |
| Manejo de Errores | 1 |
| Validaciones API | 8 |
| Transacciones BD | 2 |
| **TOTAL** | **20** |

---

### Tipos de Errores por Severidad

#### Críticos (eliminados)
- ✅ Filtros vacíos mostrando datos incorrectos
- ✅ Problemas de timezone en gráficos mensuales
- ✅ Falta de validación en API permitiendo datos inválidos

#### Altos (eliminados)
- ✅ Race conditions en generación de IDs
- ✅ Falta de transacciones causando inconsistencias
- ✅ Sin verificación de existencia en actualizaciones

#### Medios (eliminados)
- ✅ Manejo de errores incompleto
- ✅ Validaciones de rango faltantes

---

### Notas para Producción

1. **Backup Automático**: El script de deploy crea backups automáticos antes de cada actualización
2. **Base de Datos**: No se requieren cambios en el esquema de la base de datos
3. **Compatibilidad**: 100% compatible con datos existentes
4. **Testing**: Se recomienda probar en entorno de prueba antes de producción

---

### Archivos Modificados

```
index.html        - Frontend (correcciones de lógica)
api.php          - Backend (validaciones y transacciones)
deploy.bat       - Script de despliegue
CHANGELOG.md     - Este archivo
```

---

### Instrucciones de Actualización

1. Ejecutar `deploy.bat` desde Windows
2. El script subirá automáticamente:
   - index.html (con correcciones)
   - api.php (con validaciones)
   - config.php (con credenciales de producción)
   - CHANGELOG.md (documentación)
3. Verificar funcionamiento en: http://timetracker.resol.dom

---

### Próximas Mejoras Sugeridas

- [ ] Implementar sistema de logs de actividad
- [ ] Añadir exportación a PDF
- [ ] Mejorar validación de campos duplicados
- [ ] Implementar cache de datos frecuentes

---

**Nota**: Esta versión corrige todos los errores funcionales críticos identificados en la revisión de código del 2026-01-13.
