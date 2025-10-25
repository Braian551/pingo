# Guía de Integración: Código Nuevo vs Código Existente

## 🎯 Objetivo

Este documento explica cómo integrar el código refactorizado con Clean Architecture con el código existente del proyecto, permitiendo una migración gradual sin romper funcionalidad actual.

---

## 📊 Estado Actual del Proyecto

### Código Existente (No Refactorizado)
```
lib/src/features/
├── conductor/
│   ├── models/                          # Modelos originales
│   │   ├── conductor_profile_model.dart
│   │   ├── driver_license_model.dart
│   │   └── vehicle_model.dart
│   ├── providers/                       # Providers originales
│   │   └── conductor_profile_provider.dart
│   ├── services/                        # Servicios originales
│   │   ├── conductor_service.dart
│   │   └── conductor_profile_service.dart
│   └── presentation/                    # UI original
│       ├── screens/
│       └── widgets/
```

### Código Nuevo (Refactorizado)
```
lib/src/features/conductor/
├── domain/                              # NUEVO
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                                # NUEVO
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/
    └── providers/
        └── conductor_profile_provider_refactored.dart  # NUEVO
```

---

## 🔄 Estrategia de Integración

### Opción 1: Migración Progresiva (Recomendada)

Mantener ambos códigos en paralelo y migrar pantalla por pantalla.

#### Paso 1: Configurar Service Locator

En `main.dart`, inicializar el Service Locator:

```dart
import 'package:ping_go/src/core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // Inicializar dependencias del nuevo sistema
  ServiceLocator().init();

  runApp(
    MultiProvider(
      providers: [
        // Providers existentes (mantener)
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProvider()),
        
        // Provider original (mantener por ahora)
        ChangeNotifierProvider(create: (_) => ConductorProfileProvider()),
        
        // Provider refactorizado (nuevo)
        ChangeNotifierProvider(
          create: (_) => ServiceLocator().createConductorProfileProvider(),
        ),
        
        // Otros providers...
      ],
      child: const MyApp(),
    ),
  );
}
```

#### Paso 2: Usar Provider Refactorizado en Pantallas Nuevas

Para pantallas nuevas o que quieras migrar, usa el provider refactorizado:

```dart
import 'package:ping_go/src/features/conductor/presentation/providers/conductor_profile_provider_refactored.dart';

class NewConductorProfileScreen extends StatelessWidget {
  final int conductorId;
  
  @override
  Widget build(BuildContext context) {
    // Usar el provider refactorizado
    final provider = Provider.of<ConductorProfileProviderRefactored>(
      context,
      listen: false,
    );
    
    // Resto del código...
  }
}
```

#### Paso 3: Mantener Pantallas Existentes Sin Cambios

Las pantallas existentes siguen usando el provider original:

```dart
import 'package:ping_go/src/features/conductor/providers/conductor_profile_provider.dart';

class ConductorProfileScreen extends StatelessWidget {
  // Este código NO cambia, sigue usando el provider original
  final provider = Provider.of<ConductorProfileProvider>(context);
  // ...
}
```

---

### Opción 2: Migración Completa (Más Riesgosa)

Reemplazar completamente el código antiguo por el nuevo.

#### ⚠️ Advertencias
- Requiere actualizar todas las pantallas que usan `ConductorProfileProvider`
- Mayor riesgo de bugs
- Solo recomendado si tienes tests completos

#### Pasos

1. **Renombrar provider antiguo** (backup):
   ```bash
   mv conductor_profile_provider.dart conductor_profile_provider.old.dart
   ```

2. **Renombrar provider nuevo**:
   ```bash
   mv conductor_profile_provider_refactored.dart conductor_profile_provider.dart
   ```

3. **Actualizar imports** en todas las pantallas:
   ```dart
   // Antes
   import '../../providers/conductor_profile_provider.dart';
   
   // Después (mismo path, pero provider internamente refactorizado)
   import '../../providers/conductor_profile_provider.dart';
   ```

4. **Actualizar main.dart** para inyectar use cases:
   ```dart
   ChangeNotifierProvider(
     create: (_) => ServiceLocator().createConductorProfileProvider(),
   ),
   ```

---

## 🔗 Compatibilidad entre Modelos

### Problema: Dos Tipos de Modelos

**Modelo Original** (`models/conductor_profile_model.dart`):
```dart
class ConductorProfileModel {
  final DriverLicenseModel? licencia;
  final VehicleModel? vehiculo;
  // ...
}
```

**Modelo Nuevo** (`data/models/conductor_profile_model.dart`):
```dart
class ConductorProfileModel extends ConductorProfile {
  // Extiende la entidad del dominio
}
```

### Solución: Adaptadores

Crear adaptadores para convertir entre modelos si es necesario:

```dart
// lib/src/core/utils/model_adapters.dart
import '../features/conductor/models/conductor_profile_model.dart' as Old;
import '../features/conductor/data/models/conductor_profile_model.dart' as New;

class ConductorModelAdapter {
  /// Convierte modelo antiguo → modelo nuevo
  static New.ConductorProfileModel toNewModel(Old.ConductorProfileModel old) {
    return New.ConductorProfileModel(
      id: old.id ?? 0,
      conductorId: old.conductorId ?? 0,
      nombreCompleto: old.licencia?.nombreCompleto,
      // Mapear campos...
    );
  }

  /// Convierte modelo nuevo → modelo antiguo
  static Old.ConductorProfileModel toOldModel(New.ConductorProfileModel newModel) {
    return Old.ConductorProfileModel(
      licencia: Old.DriverLicenseModel(
        nombreCompleto: newModel.nombreCompleto,
        // Mapear campos...
      ),
      // ...
    );
  }
}
```

---

## 🧪 Testing Durante la Migración

### Mantener Tests Existentes

No eliminar tests del código antiguo hasta que la migración esté completa:

```
test/
├── features/
│   ├── conductor/
│   │   ├── old/                    # Tests del código original
│   │   │   └── conductor_profile_provider_test.dart
│   │   └── new/                    # Tests del código refactorizado
│   │       ├── domain/
│   │       ├── data/
│   │       └── presentation/
```

### Ejecutar Ambos Tests

```bash
# Tests del código antiguo
flutter test test/features/conductor/old/

# Tests del código nuevo
flutter test test/features/conductor/new/

# Todos los tests
flutter test
```

---

## 🎨 UI: Migración de Pantallas

### ConductorProfileScreen (Ejemplo)

#### Antes (Código Original)
```dart
class ConductorProfileScreen extends StatefulWidget {
  @override
  State<ConductorProfileScreen> createState() => _ConductorProfileScreenState();
}

class _ConductorProfileScreenState extends State<ConductorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConductorProfileProvider>(context, listen: false)
          .loadProfile(widget.conductorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConductorProfileProvider>(
      builder: (context, provider, child) {
        // UI usando provider original
      },
    );
  }
}
```

#### Después (Migrado a Clean Architecture)
```dart
class ConductorProfileScreen extends StatefulWidget {
  @override
  State<ConductorProfileScreen> createState() => _ConductorProfileScreenState();
}

class _ConductorProfileScreenState extends State<ConductorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CAMBIO: Usar provider refactorizado
      context.read<ConductorProfileProviderRefactored>()
          .loadProfile(widget.conductorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // CAMBIO: Consumer del provider refactorizado
    return Consumer<ConductorProfileProviderRefactored>(
      builder: (context, provider, child) {
        // UI exactamente igual, solo cambió el provider
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (provider.hasError) {
          return Center(child: Text('Error: ${provider.errorMessage}'));
        }
        
        final profile = provider.profile;
        if (profile == null) {
          return Center(child: Text('No se encontró el perfil'));
        }
        
        // Resto de la UI igual
        return SingleChildScrollView(
          child: Column(
            children: [
              Text(profile.nombreCompleto ?? 'Sin nombre'),
              // ...
            ],
          ),
        );
      },
    );
  }
}
```

**Cambios mínimos**:
1. Cambiar tipo del provider en `Consumer`
2. Cambiar `Provider.of` por `context.read`
3. API del provider es compatible (mismo `loadProfile`, `profile`, `isLoading`, etc.)

---

## 📦 Dependencias

### Agregar al pubspec.yaml (si no existen)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  http: ^1.0.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.0.0
  build_runner: ^2.0.0
```

---

## 🚀 Despliegue Gradual

### Fase 1: Backend Sin Cambios
- ✅ El backend PHP actual NO necesita cambios
- ✅ Los endpoints siguen siendo los mismos
- ✅ Solo cambia la organización del código Flutter

### Fase 2: Nuevas Features
- Para features nuevas, usar siempre Clean Architecture
- Crear estructura `domain/data/presentation` desde el inicio

### Fase 3: Migración de Features Existentes
- Migrar feature por feature
- Prioridad sugerida:
  1. Conductor (✅ ya migrado)
  2. Auth
  3. Map
  4. Admin

### Fase 4: Eliminar Código Antiguo
- Una vez todas las features migradas
- Ejecutar tests completos
- Eliminar carpetas `models/`, `services/`, providers antiguos

---

## 🔧 Troubleshooting

### Error: "Provider not found"

**Problema**: `Provider.of<ConductorProfileProviderRefactored>` no encuentra el provider.

**Solución**: Asegúrate de agregarlo en `main.dart`:
```dart
ChangeNotifierProvider(
  create: (_) => ServiceLocator().createConductorProfileProvider(),
),
```

### Error: "Type mismatch" en modelos

**Problema**: El modelo antiguo no es compatible con el nuevo.

**Solución**: Usar adaptadores (ver sección "Compatibilidad entre Modelos").

### Error: "Late initialization error" en ServiceLocator

**Problema**: ServiceLocator no fue inicializado.

**Solución**: Llamar `ServiceLocator().init()` en `main()` antes de `runApp()`.

---

## 📋 Checklist de Migración por Pantalla

- [ ] Identificar provider usado en la pantalla
- [ ] Verificar si hay dependencias con otras pantallas
- [ ] Actualizar import del provider
- [ ] Cambiar `Consumer<OldProvider>` por `Consumer<NewProvider>`
- [ ] Verificar que la API del provider es compatible
- [ ] Si hay diferencias, adaptar código
- [ ] Ejecutar tests de la pantalla
- [ ] Probar manualmente en emulador
- [ ] Commit con mensaje descriptivo

---

## 🎓 Recomendaciones

1. **No te apresures**: Migrar gradualmente es más seguro
2. **Testea constantemente**: Ejecuta tests después de cada cambio
3. **Documenta problemas**: Si encuentras incompatibilidades, documéntalas
4. **Usa feature flags**: Si es posible, usa flags para switchear entre implementaciones
5. **Comunica al equipo**: Avisa cuando migres una pantalla importante

---

## 📞 Soporte

Si tienes dudas sobre la migración:
1. Revisa [Clean Architecture](./CLEAN_ARCHITECTURE.md)
2. Consulta [ADR](./ADR.md) para entender decisiones
3. Revisa ejemplos en `features/conductor/` (ya migrado)
4. Pregunta al equipo en Slack/Discord

---

**Última actualización**: Octubre 2025  
**Estado**: En migración progresiva  
**Feature completada**: Conductor ✅
