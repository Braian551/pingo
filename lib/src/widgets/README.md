# Sistema de Alertas Personalizadas - Ping-Go

Este directorio contiene componentes reutilizables para mostrar alertas, diálogos y snackbars con un diseño moderno y consistente en toda la aplicación.

## 📁 Estructura

```
widgets/
├── dialogs/
│   ├── custom_dialog.dart       # Componente base de diálogos
│   └── dialog_helper.dart       # Helpers para mostrar diálogos fácilmente
└── snackbars/
    └── custom_snackbar.dart     # Snackbars personalizados
```

## 🎨 Tipos de Alertas

### Diálogos (Modales)

Los diálogos son ventanas modales que interrumpen el flujo de la aplicación y requieren acción del usuario.

#### Tipos disponibles:
- **Success** (Verde) - Para confirmaciones exitosas
- **Error** (Rojo) - Para errores y fallos
- **Warning** (Naranja) - Para advertencias
- **Info** (Amarillo) - Para información general

### Snackbars (Notificaciones)

Los snackbars son notificaciones temporales que aparecen en la parte inferior de la pantalla.

#### Tipos disponibles:
- **Success** - Operaciones exitosas
- **Error** - Mensajes de error
- **Warning** - Advertencias
- **Info** - Información general

## 🚀 Uso

### Importaciones

```dart
// Para diálogos
import 'package:ping_go/src/widgets/dialogs/dialog_helper.dart';

// Para snackbars
import 'package:ping_go/src/widgets/snackbars/custom_snackbar.dart';
```

### Ejemplos de Diálogos

#### Diálogo de Error
```dart
await DialogHelper.showError(
  context,
  title: 'Código Incorrecto',
  message: 'El código de verificación que ingresaste no es válido.',
  primaryButtonText: 'Reintentar',
);
```

#### Diálogo de Éxito
```dart
await DialogHelper.showSuccess(
  context,
  title: '¡Registro Exitoso!',
  message: 'Tu cuenta ha sido creada correctamente.',
  primaryButtonText: 'Continuar',
  onPrimaryPressed: () {
    Navigator.of(context).pop();
    // Tu lógica aquí
  },
);
```

#### Diálogo de Advertencia
```dart
await DialogHelper.showWarning(
  context,
  title: 'Aviso Importante',
  message: 'Esta acción no se puede deshacer.',
  primaryButtonText: 'Entendido',
  secondaryButtonText: 'Cancelar',
  onPrimaryPressed: () {
    // Acción primaria
  },
  onSecondaryPressed: () {
    // Acción secundaria
  },
);
```

#### Diálogo de Confirmación
```dart
final result = await DialogHelper.showConfirmation(
  context,
  title: '¿Estás seguro?',
  message: '¿Deseas eliminar este elemento?',
  confirmText: 'Eliminar',
  cancelText: 'Cancelar',
  type: DialogType.warning,
);

if (result == true) {
  // Usuario confirmó
}
```

#### Diálogo Informativo
```dart
await DialogHelper.showInfo(
  context,
  title: 'Información',
  message: 'Tu ubicación será utilizada para mejorar el servicio.',
  primaryButtonText: 'Entendido',
);
```

### Ejemplos de Snackbars

#### Snackbar de Éxito
```dart
CustomSnackbar.showSuccess(
  context,
  message: '¡Correo verificado exitosamente!',
  duration: const Duration(seconds: 3),
);
```

#### Snackbar de Error
```dart
CustomSnackbar.showError(
  context,
  message: 'No se pudo conectar al servidor',
  duration: const Duration(seconds: 4),
);
```

#### Snackbar de Advertencia
```dart
CustomSnackbar.showWarning(
  context,
  message: 'Por favor, completa todos los campos',
);
```

#### Snackbar de Información
```dart
CustomSnackbar.showInfo(
  context,
  message: 'Cargando datos...',
  duration: const Duration(seconds: 2),
);
```

#### Snackbar con Acción
```dart
CustomSnackbar.showError(
  context,
  message: 'Error al guardar los cambios',
  actionLabel: 'REINTENTAR',
  onAction: () {
    // Lógica para reintentar
  },
);
```

## 🎯 Parámetros Comunes

### Diálogos

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `context` | `BuildContext` | ✅ | Contexto de Flutter |
| `title` | `String` | ✅ | Título del diálogo |
| `message` | `String` | ✅ | Mensaje del diálogo |
| `primaryButtonText` | `String` | ❌ | Texto del botón principal (default: "Entendido") |
| `secondaryButtonText` | `String` | ❌ | Texto del botón secundario |
| `onPrimaryPressed` | `VoidCallback` | ❌ | Callback del botón principal |
| `onSecondaryPressed` | `VoidCallback` | ❌ | Callback del botón secundario |
| `barrierDismissible` | `bool` | ❌ | Si se puede cerrar tocando fuera (default: true) |

### Snackbars

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `context` | `BuildContext` | ✅ | Contexto de Flutter |
| `message` | `String` | ✅ | Mensaje a mostrar |
| `duration` | `Duration` | ❌ | Duración del snackbar |
| `actionLabel` | `String` | ❌ | Etiqueta del botón de acción |
| `onAction` | `VoidCallback` | ❌ | Callback del botón de acción |

## 🎨 Colores por Tipo

| Tipo | Color Principal | Uso |
|------|----------------|-----|
| Success | Verde (#4CAF50) | Operaciones exitosas |
| Error | Rojo (#FF5252) | Errores y fallos |
| Warning | Naranja (#FFA726) | Advertencias |
| Info | Amarillo (#FFFF00) | Información general |

## 💡 Mejores Prácticas

1. **Usa diálogos** para acciones importantes que requieren atención del usuario
2. **Usa snackbars** para notificaciones breves que no interrumpen el flujo
3. **Mensajes claros**: Sé específico sobre qué sucedió y qué debe hacer el usuario
4. **Consistencia**: Usa el mismo tipo de alerta para situaciones similares
5. **No abuses**: No muestres demasiadas alertas seguidas

## 🔄 Migración desde Alertas Antiguas

### Antes (AlertDialog estándar)
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Error'),
    content: Text('Algo salió mal'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
);
```

### Después (DialogHelper)
```dart
await DialogHelper.showError(
  context,
  title: 'Error',
  message: 'Algo salió mal',
  primaryButtonText: 'OK',
);
```

### Antes (SnackBar estándar)
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Operación exitosa'),
    backgroundColor: Colors.green,
  ),
);
```

### Después (CustomSnackbar)
```dart
CustomSnackbar.showSuccess(
  context,
  message: 'Operación exitosa',
);
```

## 🎭 Personalización Avanzada

Si necesitas personalizar aún más los diálogos, puedes usar directamente el widget `CustomDialog`:

```dart
showDialog(
  context: context,
  builder: (context) => CustomDialog(
    type: DialogType.success,
    title: 'Título Personalizado',
    message: 'Mensaje personalizado',
    customIcon: Icon(Icons.star, size: 38, color: Colors.amber),
    primaryButtonText: 'Acción',
    secondaryButtonText: 'Cancelar',
    onPrimaryPressed: () {
      // Tu lógica
    },
  ),
);
```

## 📝 Notas

- Todos los diálogos retornan `Future<void>` excepto `showConfirmation` que retorna `Future<bool?>`
- Los snackbars son automáticamente descartados después de la duración especificada
- Los diálogos pueden ser cerrados tocando fuera si `barrierDismissible: true`
- El diseño sigue el esquema de colores de Ping-Go (negro con acentos amarillos)
