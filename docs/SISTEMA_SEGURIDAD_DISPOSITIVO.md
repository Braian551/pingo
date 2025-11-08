# Sistema de Seguridad por Dispositivo - Viax

## Resumen

Se ha implementado un sistema completo de seguridad basado en dispositivo para proteger el inicio de sesión y manejar múltiples intentos fallidos:

### Características Principales

1. **Registro de Dispositivos**: Al registrarse o iniciar sesión, el dispositivo del usuario se guarda en la base de datos
2. **Dispositivo Único Activo**: Solo el último dispositivo usado es confiable - al iniciar sesión desde un nuevo dispositivo, los anteriores se invalidan automáticamente
3. **Dispositivos Desconocidos**: Desde un dispositivo diferente al último usado, se solicita verificación por código de email antes de la contraseña
4. **Bloqueo por Intentos**: Después de 5 intentos fallidos de contraseña, el dispositivo se bloquea por 15 minutos
5. **Desbloqueo por Código**: Tras el bloqueo, el usuario recibe un código por correo que restaura el acceso directamente al home

**IMPORTANTE**: Sistema de dispositivo único - cuando el usuario inicia sesión exitosamente desde un dispositivo, ese se convierte en el único dispositivo confiable. Si intenta iniciar sesión desde el dispositivo anterior, será tratado como dispositivo desconocido y requerirá verificación por código.

## Componentes Backend

### Migración
- `backend/migrations/008_device_security.sql`: Crea tabla `user_devices`

### Endpoints PHP
- `backend/auth/check_device.php`: Verifica estado del dispositivo (trusted/unknown_device/locked/user_not_found)
- `backend/auth/register.php`: Actualizado para aceptar `device_uuid` y guardarlo como confiable
- `backend/auth/login.php`: Actualizado con lógica de conteo de intentos fallidos y bloqueo
- `backend/auth/verify_code.php`: Unificado y actualizado para marcar dispositivos como confiables tras verificación

### Estructura DB
```sql
user_devices (
  id BIGINT AI,
  user_id FK usuarios(id),
  device_uuid VARCHAR(100),
  first_seen TIMESTAMP,
  last_seen TIMESTAMP,
  trusted TINYINT(1) DEFAULT 0,
  fail_attempts INT DEFAULT 0,
  locked_until TIMESTAMP NULL,
  UNIQUE(user_id, device_uuid)
)
```

## Componentes Flutter

### Servicios
- `lib/src/global/services/device_id_service.dart`: Genera UUID estable por instalación usando `device_info_plus`
- `lib/src/global/services/auth/user_service.dart`: Métodos `checkDevice()`, `verifyCodeAndTrustDevice()`, y `login()` con soporte para `device_uuid`

### Flujo de Pantallas
1. **EmailAuthScreen**: Obtiene UUID de dispositivo → llama `checkDevice()` → decide si va a Login o EmailVerification
2. **EmailVerificationScreen**: Acepta flags `fromDeviceChallenge`, `directToHomeAfterCode`, `deviceUuid`
   - Si viene de challenge + código correcto + flag directToHome → navega directo al home correspondiente
3. **LoginScreen**: Rastrea intentos fallidos localmente, envía `device_uuid` en login
   - Tras 5 intentos o flag `too_many_attempts` → redirige a EmailVerification con `directToHomeAfterCode=true`

### Dependencias
- `device_info_plus: ^10.1.0` (agregada en `pubspec.yaml`)

## Flujos de Usuario

### Flujo Normal (Dispositivo Activo/Actual)
1. Usuario ingresa email
2. Backend detecta dispositivo como `trusted` (es el último usado)
3. → Pantalla de contraseña (LoginScreen)
4. Ingresa contraseña → Home
5. **Este dispositivo se mantiene como el único confiable**

### Flujo Dispositivo Nuevo (o Previamente Usado)
1. Usuario ingresa email desde Dispositivo B
2. Backend detecta dispositivo como `unknown_device` o `needs_verification` (no es el último usado)
3. → EmailVerificationScreen con flags de challenge
4. Verifica código → Backend marca Dispositivo B como confiable **e invalida todos los demás**
5. → LoginScreen (contraseña)
6. Ingresa contraseña → Home
7. **Ahora Dispositivo B es el único confiable, Dispositivo A queda invalidado**

### Flujo Alternancia de Dispositivos
1. Usuario usa Dispositivo A → Login exitoso → A es confiable
2. Usuario cambia a Dispositivo B → Requiere código → Login exitoso → **B es confiable, A invalidado**
3. Usuario vuelve a Dispositivo A → **A ahora es "nuevo"** → Requiere código nuevamente
4. Verifica código y login → **A es confiable otra vez, B invalidado**

### Flujo Bloqueo por Intentos
1. Usuario falla contraseña 5 veces
2. Backend bloquea dispositivo por 15 min (campo `locked_until`)
3. → Redirige a EmailVerificationScreen con `directToHomeAfterCode=true`
4. Verifica código → Backend desbloquea y confía dispositivo
5. → Navega directo al Home (sin pasar por pantalla de contraseña)

## Pruebas

- **Test Dart**: `test/device_id_service_test.dart` verifica estabilidad del UUID
- **Migración**: Ejecutar `php backend/migrations/run_migrations.php` aplicó sin errores
- **Dependencias**: `flutter pub get` descargó correctamente `device_info_plus`

## Comandos Útiles

```bash
# Ejecutar migraciones
cd c:\Flutter\viax\backend
php migrations/run_migrations.php

# Actualizar dependencias Flutter
cd c:\Flutter\viax
flutter pub get

# Ejecutar tests
flutter test test/device_id_service_test.dart
```

## Notas Técnicas

- Los endpoints PHP crean la tabla `user_devices` automáticamente si no existe (idempotente)
- El UUID se genera una vez y se persiste en SharedPreferences (`viax_device_uuid`)
- Android usa `androidInfo.id` (Android ID), iOS usa `identifierForVendor`
- Web y Desktop usan UUID random estable
- **Sistema de dispositivo único**: Al hacer login exitoso, se ejecuta `UPDATE user_devices SET trusted = 0 WHERE user_id = ?` para invalidar todos los dispositivos, luego se marca solo el actual como `trusted = 1`
- El bloqueo de 15 minutos es configurable cambiando `INTERVAL 15 MINUTE` en `login.php`
- El umbral de 5 intentos es configurable cambiando la constante en `login.php` y `LoginScreen`
- **Comportamiento de suplantación**: Cada login exitoso "suplanta" al dispositivo anterior, requiriendo nueva verificación si el usuario intenta volver al dispositivo viejo

## Próximos Pasos (Opcional)

- Implementar panel de administración para ver/gestionar dispositivos confiables por usuario
- Agregar notificaciones push al detectar login desde nuevo dispositivo
- Implementar logs de auditoría más detallados para accesos sospechosos
- Considerar biometría como alternativa al código en dispositivos móviles
