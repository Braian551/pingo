# Guía Rápida - Integración de Funcionalidades de Conductor

## 🚀 Inicio Rápido

### 1. Registrar los Providers

Actualiza tu `main.dart` o el archivo donde configuras los providers:

```dart
MultiProvider(
  providers: [
    // ... otros providers existentes
    ChangeNotifierProvider(create: (_) => ConductorProvider()),
    ChangeNotifierProvider(create: (_) => ConductorProfileProvider()),
  ],
  child: MyApp(),
)
```

### 2. Configurar Rutas

Agrega las nuevas rutas en tu configuración de navegación:

```dart
// En tu MaterialApp o donde manejes las rutas
routes: {
  '/conductor/home': (context) => ConductorHomeScreen(conductorUser: ...),
  '/conductor/verification': (context) => VerificationStatusScreen(conductorId: ...),
  '/conductor/vehicle-registration': (context) => VehicleRegistrationScreen(conductorId: ...),
  // ... otras rutas
}
```

### 3. Uso Básico

#### Mostrar alerta de perfil incompleto:
```dart
final result = await ProfileIncompleteAlert.show(
  context,
  missingItems: ['Licencia de conducción', 'Vehículo'],
  dismissible: true,
);

if (result == true) {
  // Usuario quiere completar el perfil
  Navigator.push(context, ...);
}
```

#### Mostrar alerta de documento próximo a vencer:
```dart
await DocumentExpiryAlert.show(
  context,
  documentName: 'licencia de conducción',
  expiryDate: DateTime(2025, 12, 31),
);
```

#### Cargar perfil del conductor:
```dart
final provider = Provider.of<ConductorProfileProvider>(context, listen: false);
await provider.loadProfile(conductorId);

// Acceder al perfil
final profile = provider.profile;
if (profile != null) {
  print('Completitud: ${(profile.completionPercentage * 100).toInt()}%');
  print('Estado: ${profile.estadoVerificacion.label}');
}
```

#### Actualizar vehículo:
```dart
final vehicle = VehicleModel(
  placa: 'ABC123',
  tipo: VehicleType.carro,
  marca: 'Toyota',
  modelo: 'Corolla',
  anio: 2020,
  color: 'Blanco',
  soatNumero: '123456',
  soatVencimiento: DateTime(2026, 12, 31),
  // ...
);

final success = await provider.updateVehicle(
  conductorId: conductorId,
  vehicle: vehicle,
);
```

## 📱 Navegación Entre Pantallas

### Desde ConductorHomeScreen a Verificación:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VerificationStatusScreen(
      conductorId: conductorId,
    ),
  ),
);
```

### Desde cualquier pantalla a Registro de Vehículo:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VehicleRegistrationScreen(
      conductorId: conductorId,
    ),
  ),
).then((result) {
  // Recargar datos después de registrar
  if (result == true) {
    _loadConductorData();
  }
});
```

## 🎨 Personalización

### Cambiar colores de alertas:
```dart
ConfirmationAlert.show(
  context,
  title: 'Confirmar Acción',
  message: '¿Estás seguro?',
  accentColor: Colors.blue, // Personalizar color
  icon: Icons.info_rounded,  // Personalizar icono
);
```

### Validar perfil manualmente:
```dart
final profile = provider.profile;

// Verificar si puede activar disponibilidad
if (profile?.canBeAvailable ?? false) {
  // Permitir activar disponibilidad
} else {
  // Mostrar alerta
  ProfileIncompleteAlert.show(context, ...);
}
```

## ⚠️ Manejo de Errores

### En servicios:
```dart
try {
  final result = await ConductorProfileService.updateVehicle(...);
  
  if (result['success'] == true) {
    // Éxito
  } else {
    // Mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Error')),
    );
  }
} catch (e) {
  // Manejar excepción
  print('Error: $e');
}
```

### Con Providers:
```dart
await provider.updateLicense(...);

if (provider.errorMessage != null) {
  // Mostrar error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.errorMessage!)),
  );
} else {
  // Éxito
}
```

## 🔍 Debug y Testing

### Verificar estado del perfil:
```dart
print('Perfil completo: ${profile?.isProfileComplete}');
print('Puede estar disponible: ${profile?.canBeAvailable}');
print('Tareas pendientes: ${profile?.pendingTasks}');
print('Porcentaje: ${(profile?.completionPercentage ?? 0) * 100}%');
```

### Ver datos de licencia:
```dart
final license = profile?.licencia;
print('Licencia válida: ${license?.isValid}');
print('Días hasta vencimiento: ${license?.daysUntilExpiry}');
print('Vence pronto: ${license?.isExpiringSoon}');
```

### Ver datos de vehículo:
```dart
final vehicle = profile?.vehiculo;
print('Datos básicos completos: ${vehicle?.isBasicComplete}');
print('Documentos completos: ${vehicle?.isDocumentsComplete}');
print('Todo completo: ${vehicle?.isComplete}');
```

## 📝 Checklist de Implementación

- [ ] Agregar providers al árbol de widgets
- [ ] Configurar rutas de navegación
- [ ] Implementar endpoints del backend (ver NUEVAS_FUNCIONALIDADES.md)
- [ ] Probar flujo completo de registro
- [ ] Probar alertas en diferentes escenarios
- [ ] Verificar manejo de errores
- [ ] Testear con perfil incompleto
- [ ] Testear con documentos vencidos
- [ ] Validar UI en diferentes dispositivos
- [ ] Implementar image_picker para fotos (opcional)

## 🐛 Problemas Comunes

### Provider no encontrado:
```dart
// Solución: Asegúrate de que el provider está registrado en el árbol de widgets
// y que estás usando el contexto correcto
final provider = Provider.of<ConductorProfileProvider>(
  context, 
  listen: false,
);
```

### Navegación no funciona:
```dart
// Verifica que tienes un Navigator en el árbol de widgets
// y que el contexto es correcto
Navigator.of(context).push(...);
```

### Datos no se actualizan:
```dart
// Usa notifyListeners() en el provider después de cambios
// O usa Consumer para escuchar cambios:
Consumer<ConductorProfileProvider>(
  builder: (context, provider, child) {
    return YourWidget(data: provider.profile);
  },
)
```

## 📚 Recursos Adicionales

- Ver `NUEVAS_FUNCIONALIDADES.md` para documentación completa
- Revisar modelos en `lib/src/features/conductor/models/`
- Ejemplo de uso en `conductor_home_screen.dart`
- Componentes reutilizables en `widgets/conductor_alerts.dart`

## 💡 Tips de Desarrollo

1. **Usa Consumer cuando necesites reactividad:**
   ```dart
   Consumer<ConductorProfileProvider>(
     builder: (context, provider, child) => ...,
   )
   ```

2. **Llama a loadProfile al iniciar:**
   ```dart
   @override
   void initState() {
     super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<ConductorProfileProvider>(context, listen: false)
         .loadProfile(conductorId);
     });
   }
   ```

3. **Valida antes de permitir acciones:**
   ```dart
   if (profile?.isProfileComplete ?? false) {
     // Permitir acción
   } else {
     // Mostrar alerta
   }
   ```

4. **Maneja estados de carga:**
   ```dart
   if (provider.isLoading) {
     return CircularProgressIndicator();
   }
   ```

5. **Refresca después de actualizar:**
   ```dart
   await provider.updateVehicle(...);
   await provider.loadProfile(conductorId); // Recargar
   ```

---

Para más información, consulta la documentación completa en `NUEVAS_FUNCIONALIDADES.md`
