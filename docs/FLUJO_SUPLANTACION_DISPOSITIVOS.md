# Flujo de Suplantación de Dispositivos - Viax

## Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                    ESTADO INICIAL                                │
│  Usuario sin dispositivos registrados                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PRIMER LOGIN - Dispositivo A                                    │
│  ────────────────────────────────────────────────────────────── │
│  1. Usuario registra cuenta desde Dispositivo A                  │
│  2. device_uuid de A se guarda como confiable (trusted=1)        │
│  3. Usuario accede al Home                                       │
│                                                                   │
│  Estado DB:                                                       │
│  ┌──────────────┬──────────┬────────┐                           │
│  │ device_uuid  │ trusted  │ user   │                           │
│  ├──────────────┼──────────┼────────┤                           │
│  │ A            │ 1        │ user_1 │  ← ÚNICO CONFIABLE        │
│  └──────────────┴──────────┴────────┘                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAMBIO A DISPOSITIVO B                                          │
│  ────────────────────────────────────────────────────────────── │
│  1. Usuario intenta login desde Dispositivo B                    │
│  2. Backend detecta B como "desconocido" (no confiable)         │
│  3. Se envía código de verificación al email                     │
│  4. Usuario ingresa código + contraseña                          │
│  5. Login exitoso → Se ejecuta:                                  │
│     • UPDATE user_devices SET trusted=0 WHERE user_id=user_1    │
│     • UPDATE user_devices SET trusted=1 WHERE device_uuid=B     │
│                                                                   │
│  Estado DB:                                                       │
│  ┌──────────────┬──────────┬────────┐                           │
│  │ device_uuid  │ trusted  │ user   │                           │
│  ├──────────────┼──────────┼────────┤                           │
│  │ A            │ 0        │ user_1 │  ← YA NO CONFIABLE        │
│  │ B            │ 1        │ user_1 │  ← NUEVO CONFIABLE        │
│  └──────────────┴──────────┴────────┘                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  VOLVER A DISPOSITIVO A                                          │
│  ────────────────────────────────────────────────────────────── │
│  1. Usuario intenta login desde Dispositivo A nuevamente         │
│  2. Backend detecta A como "desconocido" (trusted=0)            │
│  3. Se envía código de verificación al email                     │
│  4. Usuario ingresa código + contraseña                          │
│  5. Login exitoso → Se ejecuta:                                  │
│     • UPDATE user_devices SET trusted=0 WHERE user_id=user_1    │
│     • UPDATE user_devices SET trusted=1 WHERE device_uuid=A     │
│                                                                   │
│  Estado DB:                                                       │
│  ┌──────────────┬──────────┬────────┐                           │
│  │ device_uuid  │ trusted  │ user   │                           │
│  ├──────────────┼──────────┼────────┤                           │
│  │ A            │ 1        │ user_1 │  ← CONFIABLE OTRA VEZ     │
│  │ B            │ 0        │ user_1 │  ← YA NO CONFIABLE        │
│  └──────────────┴──────────┴────────┘                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    Ciclo se repite...
```

## Casos de Uso Reales

### Caso 1: Usuario cambia de teléfono
```
Día 1: Login en iPhone viejo → iPhone es confiable
Día 5: Compra iPhone nuevo → Login requiere código → iPhone nuevo es confiable
Día 6: Si intenta usar iPhone viejo → Requiere código nuevamente
```

### Caso 2: Usuario con múltiples dispositivos
```
Usuario tiene:
- Celular personal
- Tablet del trabajo  
- Computadora de casa

Solo el ÚLTIMO dispositivo usado es confiable.
Los demás requieren verificación por código cada vez.
```

### Caso 3: Seguridad ante robo
```
Si roban el teléfono:
1. Usuario inicia sesión desde otro dispositivo
2. Teléfono robado queda invalidado automáticamente
3. Ladrón no puede acceder sin verificación por email
```

## Ventajas del Sistema

✅ **Mayor Seguridad**: Solo un dispositivo activo a la vez reduce superficie de ataque
✅ **Control Simple**: Usuario no necesita gestionar lista de dispositivos manualmente
✅ **Protección Automática**: Cambiar de dispositivo invalida los anteriores sin acción del usuario
✅ **Auditoría Clara**: Siempre sabes cuál fue el último dispositivo usado

## Consideraciones

⚠️ **UX Trade-off**: Usuario necesitará verificación cada vez que alterne entre dispositivos
⚠️ **Email Accesible**: Usuario debe tener acceso a su email para usar múltiples dispositivos
💡 **Recomendación**: Documentar claramente este comportamiento en la UI/onboarding

## Código Clave

### En `login.php` (login exitoso)
```php
// Invalidar todos los dispositivos del usuario
$invalidate = $db->prepare('UPDATE user_devices SET trusted = 0 WHERE user_id = ?');
$invalidate->execute([$user['id']]);

// Marcar solo este dispositivo como confiable
$upd = $db->prepare('UPDATE user_devices SET trusted = 1 WHERE id = ?');
$upd->execute([$device['id']]);
```

### En `verify_code.php` (después de verificación)
```php
// Invalidar todos los dispositivos
$invalidateAll = $pdo->prepare('UPDATE user_devices SET trusted = 0 WHERE user_id = ?');
$invalidateAll->execute([$user['id']]);

// Marcar solo este como confiable
$updDev = $pdo->prepare('UPDATE user_devices SET trusted = 1 WHERE id = ?');
$updDev->execute([$dev['id']]);
```
