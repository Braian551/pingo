# Alerta Dinámica de Perfil Incompleto

## Descripción

Se ha implementado una funcionalidad dinámica en la alerta de perfil incompleto que cambia el botón y el mensaje según lo que el conductor necesite completar.

## Tipos de Acciones

### 1. **Registrar Licencia** (`ProfileAction.registerLicense`)
- **Cuándo se muestra**: Cuando el conductor no tiene licencia registrada o está incompleta
- **Título**: "Falta tu Licencia"
- **Mensaje**: "Necesitas registrar tu licencia de conducción para poder activar tu disponibilidad."
- **Botón**: "Registrar Licencia"
- **Acción**: Navega a `LicenseRegistrationScreen`

### 2. **Registrar Vehículo** (`ProfileAction.registerVehicle`)
- **Cuándo se muestra**: Cuando el conductor tiene licencia pero no tiene vehículo registrado o está incompleto
- **Título**: "Falta tu Vehículo"
- **Mensaje**: "Necesitas registrar tu vehículo para poder activar tu disponibilidad."
- **Botón**: "Registrar Vehículo"
- **Acción**: Navega a `VehicleOnlyRegistrationScreen`

### 3. **Enviar Verificación** (`ProfileAction.submitVerification`)
- **Cuándo se muestra**: Cuando el perfil está completo pero pendiente de verificación
- **Título**: "Perfil Listo"
- **Mensaje**: "Tu perfil está completo. Envíalo para verificación y podrás empezar a recibir viajes."
- **Botón**: "Ver Mi Perfil"
- **Acción**: Navega a `ConductorProfileScreen`

### 4. **Completar Perfil** (`ProfileAction.completeProfile`)
- **Cuándo se muestra**: Caso general cuando faltan varios elementos
- **Título**: "Perfil Incompleto"
- **Mensaje**: "Para activar tu disponibilidad y recibir viajes, debes completar tu perfil de conductor."
- **Botón**: "Completar Ahora"
- **Acción**: Navega a `ConductorProfileScreen`

## Función Helper

```dart
ProfileAction getProfileActionType(ConductorProfileModel? profile) {
  if (profile == null) {
    return ProfileAction.completeProfile;
  }

  // Si no tiene licencia o está incompleta
  if (profile.licencia == null || !profile.licencia!.isComplete) {
    return ProfileAction.registerLicense;
  }

  // Si no tiene vehículo o está incompleto
  if (profile.vehiculo == null || !profile.vehiculo!.isBasicComplete) {
    return ProfileAction.registerVehicle;
  }

  // Si el perfil está completo pero no se ha enviado para verificación
  if (profile.isProfileComplete && 
      profile.estadoVerificacion == VerificationStatus.pendiente) {
    return ProfileAction.submitVerification;
  }

  // Caso por defecto
  return ProfileAction.completeProfile;
}
```

## Uso en el Código

### En `conductor_home_screen.dart`

```dart
// Determinar el tipo de acción según el perfil
final actionType = getProfileActionType(profile);

// Mostrar la alerta con el tipo de acción
final shouldComplete = await ProfileIncompleteAlert.show(
  context,
  missingItems: profile.pendingTasks,
  dismissible: true,
  actionType: actionType, // Nuevo parámetro
);

// Manejar la acción seleccionada
if (shouldComplete == true && mounted) {
  _handleProfileAction(actionType, profile);
}
```

### Método `_handleProfileAction`

```dart
void _handleProfileAction(ProfileAction actionType, ConductorProfileModel profile) {
  switch (actionType) {
    case ProfileAction.registerLicense:
      // Navega a registro de licencia
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LicenseRegistrationScreen(
            conductorId: _conductorId!,
            existingLicense: profile.licencia,
          ),
        ),
      ).then((result) {
        if (result == true) {
          // Recargar perfil
          profileProvider.loadProfile(_conductorId!);
        }
      });
      break;

    case ProfileAction.registerVehicle:
      // Navega a registro de vehículo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleOnlyRegistrationScreen(
            conductorId: _conductorId!,
            existingVehicle: profile.vehiculo,
          ),
        ),
      ).then((result) {
        if (result == true) {
          profileProvider.loadProfile(_conductorId!);
        }
      });
      break;

    case ProfileAction.submitVerification:
    case ProfileAction.completeProfile:
      // Navega al perfil completo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConductorProfileScreen(
            conductorId: _conductorId!,
          ),
        ),
      ).then((result) {
        profileProvider.loadProfile(_conductorId!);
      });
      break;
  }
}
```

## Flujo de Usuario

1. **Usuario intenta activar disponibilidad**
   - El sistema verifica el perfil del conductor

2. **Si falta la licencia**
   - Muestra alerta "Falta tu Licencia"
   - Botón "Registrar Licencia"
   - Al hacer clic, va directamente al formulario de licencia

3. **Si falta el vehículo** (ya tiene licencia)
   - Muestra alerta "Falta tu Vehículo"
   - Botón "Registrar Vehículo"
   - Al hacer clic, va directamente al formulario de vehículo

4. **Si está todo completo pero sin verificar**
   - Muestra alerta "Perfil Listo"
   - Botón "Ver Mi Perfil"
   - Al hacer clic, va al perfil donde puede enviar para verificación

## Beneficios

- ✅ **Navegación Directa**: El usuario va directamente a donde necesita completar información
- ✅ **Mensajes Contextuales**: Cada alerta muestra exactamente qué falta
- ✅ **Mejor UX**: No hay pasos innecesarios ni confusión
- ✅ **Progresivo**: Guía al usuario paso a paso en el orden correcto
- ✅ **Claro**: Los mensajes y botones son específicos a cada situación

## Prioridad de Acciones

El sistema prioriza las acciones en este orden:

1. **Licencia** (más importante)
2. **Vehículo**
3. **Enviar verificación**
4. **Completar perfil general**

Esta priorización asegura que el conductor complete los elementos en un orden lógico y necesario.
