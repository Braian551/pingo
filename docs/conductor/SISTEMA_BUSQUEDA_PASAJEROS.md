# Sistema de Búsqueda de Pasajeros para Conductores

## 📋 Descripción

Se ha implementado un sistema completo de búsqueda de pasajeros siguiendo la lógica de Uber/DiDi para los conductores. Cuando un conductor activa su disponibilidad, automáticamente entra a un modo de búsqueda activa de solicitudes cercanas.

## 🎯 Funcionalidades Implementadas

### 1. **Pantalla de Búsqueda de Pasajeros**
   - **Archivo**: `conductor_searching_passengers_screen.dart`
   - Mapa con ubicación en tiempo real del conductor
   - Búsqueda automática cada 5 segundos de solicitudes cercanas
   - Marcadores en el mapa para solicitudes disponibles
   - Efecto glass con opacidad (sin degradados)
   - Colores sólidos amarillo (#FFFF00) y negro (#1A1A1A)

### 2. **Servicio de Búsqueda de Solicitudes**
   - **Archivo**: `trip_request_search_service.dart`
   - Búsqueda continua mediante Timer cada 5 segundos
   - Radio de búsqueda configurable (default: 5 km)
   - Actualización automática de ubicación del conductor
   - Funciones para aceptar/rechazar solicitudes

### 3. **Integración con Home del Conductor**
   - **Modificado**: `conductor_home_screen.dart`
   - Al activar toggle → Navega a pantalla de búsqueda
   - Verifica perfil completo antes de permitir disponibilidad
   - Al desactivar → Vuelve al estado offline
   - Recarga viajes activos al regresar de una aceptación

### 4. **Endpoints Backend PHP**
   - **`get_solicitudes_pendientes.php`**: Busca solicitudes cercanas usando Haversine
   - **`accept_trip_request.php`**: Acepta solicitud y crea asignación
   - **`reject_trip_request.php`**: Registra rechazo del conductor
   - **`update_location.php`**: Actualiza ubicación en tiempo real

## 🎨 Diseño

### Colores y Estilo
- **Fondo**: Negro sólido `#121212` y `#1A1A1A`
- **Acentos**: Amarillo `#FFFF00` (sin degradados)
- **Efecto glass**: `BackdropFilter` con blur
- **Opacidad**: Transparencias sutiles para paneles

### Componentes Visuales
- Panel superior: Estado de búsqueda con efecto glass
- Mapa: Estilo oscuro de Mapbox
- Marcador conductor: Pulso animado amarillo
- Marcadores solicitudes: Blancos/Amarillos según selección
- Panel inferior: Información del viaje con botones de acción

## 🔄 Flujo de Usuario (Lógica Uber/DiDi)

```
1. Conductor activa toggle en Home
   ↓
2. Sistema verifica perfil completo
   ↓
3. Navega a pantalla de búsqueda
   ↓
4. Inicia tracking de ubicación GPS
   ↓
5. Búsqueda automática cada 5 segundos
   ↓
6. Muestra solicitudes cercanas en mapa
   ↓
7. Conductor puede:
   - Ver detalles de la solicitud
   - Aceptar → Navega a viaje activo
   - Rechazar → Continúa buscando
   ↓
8. Al salir, detiene búsqueda
```

## 📡 Comunicación Backend

### Búsqueda de Solicitudes
```dart
POST /conductor/get_solicitudes_pendientes.php
{
  "conductor_id": 7,
  "latitud_actual": 4.6097,
  "longitud_actual": -74.0817,
  "radio_km": 5.0
}
```

**Respuesta**:
```json
{
  "success": true,
  "total": 2,
  "solicitudes": [
    {
      "id": 15,
      "nombre_usuario": "Juan Pérez",
      "latitud_origen": 4.6100,
      "longitud_origen": -74.0820,
      "direccion_origen": "Calle 100",
      "direccion_destino": "Calle 50",
      "distancia_km": 5.2,
      "precio_estimado": 15000,
      "distancia_conductor_origen": 0.35
    }
  ]
}
```

### Aceptar Solicitud
```dart
POST /conductor/accept_trip_request.php
{
  "solicitud_id": 15,
  "conductor_id": 7
}
```

### Rechazar Solicitud
```dart
POST /conductor/reject_trip_request.php
{
  "solicitud_id": 15,
  "conductor_id": 7,
  "motivo": "Conductor rechazó"
}
```

## 🔧 Configuración

### Variables del Servicio
```dart
// En trip_request_search_service.dart
static const double searchRadiusKm = 5.0;  // Radio de búsqueda
static const int searchIntervalSeconds = 5; // Intervalo de búsqueda
```

### Permisos Requeridos

**Android** (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte solicitudes cercanas</string>
```

## 📊 Características Técnicas

### Animaciones
- **Pulso del marcador**: 1.5s loop con easeInOut
- **Slide del panel**: 400ms easeOutCubic
- **Escala de marcadores**: elasticOut con bounce

### Optimizaciones
- Búsqueda cada 5 segundos (no bombardea el servidor)
- Cancela búsqueda al salir de la pantalla
- Actualiza ubicación cada 10 metros (no cada movimiento)
- Límite de 10 solicitudes por búsqueda

### Manejo de Errores
- Verifica permisos de ubicación
- Muestra errores con SnackBar
- Diálogo de confirmación al salir
- Valida perfil antes de activar

## 🎯 Próximos Pasos

1. **Crear pantalla de viaje activo**: Cuando acepta, mostrar ruta al origen
2. **Notificaciones push**: Alertar de nuevas solicitudes
3. **Sonido de notificación**: Audio al recibir solicitud
4. **Timer de expiración**: Auto-rechazar si no responde en X segundos
5. **Historial de rechazos**: No mostrar solicitudes rechazadas previamente

## 🐛 Debugging

### Si no encuentra solicitudes:
1. Verifica que hay solicitudes pendientes en la BD
2. Confirma que el tipo de vehículo coincida
3. Revisa el radio de búsqueda (aumentar a 10km para pruebas)
4. Verifica que la ubicación GPS esté activa

### Si no conecta con backend:
1. Confirma que usas `10.0.2.2` en emulador
2. En dispositivo físico, usa la IP local de tu PC
3. Verifica que Laragon/Apache estén corriendo
4. Revisa logs de Flutter para errores HTTP

## 📝 Notas Importantes

- El toggle en el AppBar ahora navega en lugar de solo cambiar estado
- La búsqueda se detiene automáticamente al salir
- El conductor no puede activarse si su perfil no está completo
- Las solicitudes se ordenan por distancia (más cercanas primero)
- Solo muestra solicitudes de los últimos 15 minutos
