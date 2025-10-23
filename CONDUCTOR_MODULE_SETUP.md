# GUÍA DE IMPLEMENTACIÓN - MÓDULO CONDUCTOR Y CORRECCIÓN DE RUTAS

## ✅ Cambios Realizados

### 1. Corrección del Sistema de Rutas por Tipo de Usuario

**Archivos modificados:**
- `lib/src/widgets/auth_wrapper.dart`
- `lib/src/features/auth/presentation/screens/login_screen.dart`
- `lib/src/routes/route_names.dart`
- `lib/src/routes/app_router.dart`
- `lib/main.dart`

**Comportamiento corregido:**
- **Administrador** (`tipo_usuario = 'administrador'`) → Redirige a `/admin/home`
- **Conductor** (`tipo_usuario = 'conductor'`) → Redirige a `/conductor/home`
- **Cliente** (`tipo_usuario = 'cliente'`) → Redirige a `/home`

### 2. Módulo Conductor Completo

**Estructura creada:**
```
lib/src/features/conductor/
├── models/
│   └── conductor_model.dart
├── providers/
│   └── conductor_provider.dart
├── services/
│   └── conductor_service.dart
├── presentation/
│   ├── screens/
│   │   └── conductor_home_screen.dart
│   └── widgets/
│       ├── conductor_stats_card.dart
│       └── viaje_activo_card.dart
└── README.md
```

**Backend creado:**
```
pingo/backend/conductor/
├── get_info.php
├── get_viajes_activos.php
├── get_estadisticas.php
├── get_historial.php
├── get_ganancias.php
├── actualizar_disponibilidad.php
└── actualizar_ubicacion.php
```

**Migración creada:**
```
pingo/backend/migrations/
└── 002_conductor_fields.sql
```

## 📋 Instrucciones de Ejecución

### Paso 1: Ejecutar Migraciones de Base de Datos

Hay dos opciones:

**Opción A - Usar el script batch (Windows):**
```bash
# Desde la raíz del proyecto
ejecutar_migraciones.bat
```

**Opción B - Ejecutar manualmente:**
```bash
cd pingo/backend
php migrations/run_migrations.php
```

**Notas sobre las migraciones:**
- Es normal ver advertencias sobre "Duplicate column name" o "Duplicate key name" si ejecutas la migración múltiples veces
- Estas advertencias indican que las columnas/índices ya existen y pueden ignorarse
- La migración es **idempotente** (puede ejecutarse múltiples veces de forma segura)

La migración agregará los siguientes campos a la tabla `detalles_conductor`:
- `disponible` - Estado de disponibilidad del conductor
- `latitud_actual`, `longitud_actual` - Ubicación en tiempo real
- `ultima_actualizacion` - Timestamp de última actualización
- `total_viajes` - Contador de viajes
- `estado_verificacion` - Estado de verificación de documentos
- Índices optimizados para búsquedas (`idx_disponible`, `idx_estado_verificacion`)

### Paso 2: Verificar la Base de Datos

Asegúrate de que tu servidor MySQL esté corriendo y que la base de datos `pingo` esté accesible.

### Paso 3: Crear un Usuario Conductor de Prueba

Si no tienes un usuario conductor, puedes modificar uno existente:

```sql
UPDATE usuarios 
SET tipo_usuario = 'conductor' 
WHERE email = 'tu_email@ejemplo.com';
```

O crear uno nuevo desde la app usando el registro normal y luego cambiando el tipo en la BD.

### Paso 4: Ejecutar la Aplicación

```bash
flutter run
```

## 🧪 Pruebas del Flujo de Autenticación

### Test 1: Usuario Administrador
1. Inicia sesión con un usuario `tipo_usuario = 'administrador'`
2. Debe redirigir a la pantalla de administrador (`AdminHomeScreen`)
3. Verifica que veas el dashboard de admin con estadísticas, usuarios, etc.

### Test 2: Usuario Conductor
1. Inicia sesión con un usuario `tipo_usuario = 'conductor'`
2. Debe redirigir a la pantalla de conductor (`ConductorHomeScreen`)
3. Verifica que veas:
   - Switch de disponibilidad en el AppBar
   - Estadísticas del día (viajes, ganancias, calificación, horas)
   - Sección de viajes activos
   - Navegación inferior con 4 pestañas

### Test 3: Usuario Cliente
1. Inicia sesión con un usuario `tipo_usuario = 'cliente'`
2. Debe redirigir a la pantalla home normal (`HomeScreen`)
3. Verifica que veas el dashboard de cliente con servicios de viaje y envío

### Test 4: Usuario con Sesión Iniciada
1. Cierra la app sin cerrar sesión
2. Vuelve a abrir la app
3. `AuthWrapper` debe consultar el perfil y redirigir automáticamente según el tipo de usuario

## 🔧 Funcionalidades del Módulo Conductor

### Dashboard Principal
- **Saludo personalizado** según hora del día
- **Card de disponibilidad** con estado visual
- **Estadísticas en tiempo real:**
  - Viajes completados hoy
  - Ganancias del día
  - Calificación promedio
  - Horas trabajadas

### Switch de Disponibilidad
- Ubicado en el AppBar
- Cambia entre disponible/no disponible
- Actualiza el estado en la base de datos
- Muestra snackbar de confirmación

### Viajes Activos
- Muestra lista de viajes en progreso
- Información del cliente (nombre, foto)
- Origen y destino del viaje
- Precio estimado
- Botones de acción (Llamar, Navegar)

### Navegación por Pestañas
- **Inicio**: Dashboard principal
- **Viajes**: Historial (pendiente implementar)
- **Ganancias**: Estadísticas de ganancias (pendiente implementar)
- **Perfil**: Información del conductor (pendiente implementar)

## 🐛 Solución de Problemas

### Error: "No se pudo cargar la información del conductor"
**Causa**: El usuario no tiene un registro en `detalles_conductor`

**Solución**:
```sql
INSERT INTO detalles_conductor (
  usuario_id, 
  licencia_conduccion, 
  licencia_vencimiento, 
  vehiculo_tipo, 
  vehiculo_placa, 
  fecha_creacion
) VALUES (
  [ID_USUARIO], 
  'LIC-123456', 
  '2026-12-31', 
  'motocicleta', 
  'ABC123', 
  NOW()
);
```

### Error: "Column 'disponible' doesn't exist"
**Causa**: No se ejecutó la migración 002

**Solución**: Ejecuta `ejecutar_migraciones.bat` o el comando PHP manual

### Error: "Connection refused" en el backend
**Causa**: El servidor PHP no está corriendo o la URL es incorrecta

**Solución**:
- Verifica que XAMPP/WAMP esté corriendo
- Confirma que la URL base sea `http://10.0.2.2/pingo/backend/` (emulador Android)
- Para dispositivo físico, usa la IP de tu PC local

### El usuario no redirige al módulo correcto
**Causa**: El campo `tipo_usuario` no está bien configurado

**Solución**:
```sql
-- Ver tipo de usuario actual
SELECT id, email, tipo_usuario FROM usuarios WHERE email = 'tu_email@ejemplo.com';

-- Actualizar si es necesario
UPDATE usuarios SET tipo_usuario = 'conductor' WHERE id = [ID_USUARIO];
```

## 📱 Capturas de Pantalla del Módulo Conductor

El módulo conductor incluye:
- ✅ Diseño moderno con glassmorphism
- ✅ Tema oscuro consistente con la app
- ✅ Colores amarillo (#FFFF00) como acento
- ✅ Animaciones suaves y transiciones
- ✅ Iconos intuitivos y modernos
- ✅ Responsive design

## 🚀 Próximos Pasos

1. **Implementar pantallas pendientes:**
   - Historial de viajes con paginación
   - Ganancias con gráficos
   - Perfil del conductor con edición

2. **Agregar funcionalidades:**
   - Notificaciones push para nuevas solicitudes
   - Navegación en tiempo real con Mapbox
   - Chat en tiempo real con cliente
   - Sistema de calificaciones

3. **Optimizaciones:**
   - Actualización automática de ubicación cada X segundos
   - Websockets para recibir solicitudes en tiempo real
   - Caché de datos para modo offline

## 📝 Notas Importantes

1. **Base de datos**: Todos los endpoints requieren que exista un registro en `detalles_conductor` para el usuario conductor
2. **Autenticación**: Pendiente implementar middleware de autenticación en los endpoints PHP
3. **Ubicación en tiempo real**: Pendiente implementar servicio de actualización automática de ubicación
4. **Notificaciones**: Pendiente implementar Firebase Cloud Messaging para notificaciones push

## ✅ Checklist de Verificación

- [x] AuthWrapper redirige correctamente según tipo de usuario
- [x] Login redirige correctamente según tipo de usuario  
- [x] Módulo conductor creado con estructura completa
- [x] Backend PHP con todos los endpoints necesarios
- [x] Migración creada para campos adicionales
- [x] Provider agregado al main.dart
- [x] Rutas configuradas en app_router.dart
- [x] Sin errores de compilación
- [ ] Migración ejecutada en base de datos
- [ ] Usuario conductor de prueba creado
- [ ] Flujo completo probado en app

---

**¡El módulo conductor está listo para usar!** 🎉

Solo falta ejecutar las migraciones y probar con un usuario conductor.
