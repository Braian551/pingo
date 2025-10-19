# 🗺️ Configuración de APIs de Mapas - PingGo

## 📋 Resumen de la Arquitectura

Este proyecto utiliza una **combinación inteligente de APIs** para optimizar costos mientras mantiene funcionalidad profesional:

### 🎯 APIs Utilizadas

| Servicio | API | Propósito | Plan | Límite |
|----------|-----|-----------|------|--------|
| **Mapas** | Mapbox | Visualización y tiles | Free | 100k/mes |
| **Rutas** | Mapbox Directions | Navegación y rutas | Free | 100k/mes |
| **Geocoding** | Nominatim (OSM) | Dirección ↔ Coordenadas | Free | Ilimitado* |
| **Tráfico** | TomTom | Flujo e incidentes | Free | 2,500/día |

*Nominatim recomienda máximo 1 request/segundo

---

## 🔧 Configuración Inicial

### 1️⃣ Obtener API Keys

#### Mapbox (REQUERIDO)
1. Ve a [Mapbox Account](https://account.mapbox.com/)
2. Regístrate o inicia sesión
3. Crea un nuevo **Access Token**
4. Copia tu token público (empieza con `pk.`)

**Tu token actual:**
```
pk.eyJ1IjoiYnJhaW5waW5nbzIiLCJhIjoiY21neHYzYnF3MWprMTJ3cHU4M3kzeHM1aiJ9.ICn4bFPZVRHcf2fyW7qBEA
```

#### TomTom (OPCIONAL - para tráfico)
1. Ve a [TomTom Developer Portal](https://developer.tomtom.com/)
2. Regístrate para obtener una cuenta gratuita
3. Crea una nueva aplicación
4. Copia tu API Key

#### Nominatim (NO REQUIERE KEY)
- Nominatim es completamente gratuito
- Solo requiere un User-Agent identificativo
- Ya configurado en el proyecto

---

### 2️⃣ Configurar el Proyecto

#### Archivo de Configuración

El archivo `lib/src/core/config/env_config.dart` **ya está creado** con tu token de Mapbox.

Si necesitas modificarlo:

```dart
// lib/src/core/config/env_config.dart
class EnvConfig {
  // Token público de Mapbox
  static const String mapboxPublicToken = 'TU_TOKEN_AQUI';
  
  // Token de TomTom (opcional)
  static const String tomtomApiKey = 'TU_KEY_AQUI';
  
  // Nominatim (ya configurado)
  static const String nominatimUserAgent = 'PingGo App';
  static const String nominatimEmail = 'traconmaster@gmail.com';
}
```

#### ⚠️ Seguridad

El archivo `env_config.dart` **NO se sube a Git** (está en `.gitignore`).

Si trabajas en equipo:
1. Copia `env_config.dart.example`
2. Renómbralo a `env_config.dart`
3. Añade tus propias API keys

---

## 📦 Instalación de Dependencias

```powershell
flutter pub get
```

---

## 🚀 Uso de las APIs

### 📍 Mapbox - Mapas y Rutas

#### Calcular Ruta
```dart
final mapProvider = Provider.of<MapProvider>(context, listen: false);

await mapProvider.calculateRoute(
  origin: LatLng(4.6097, -74.0817),      // Bogotá
  destination: LatLng(6.2476, -75.5658),  // Medellín
  profile: 'driving', // driving, walking, cycling
);

// Acceder a la ruta
final route = mapProvider.currentRoute;
print('Distancia: ${route?.formattedDistance}');
print('Duración: ${route?.formattedDuration}');
```

#### Optimizar Ruta (múltiples paradas)
```dart
await mapProvider.calculateRoute(
  origin: origin,
  destination: destination,
  waypoints: [punto1, punto2, punto3], // Paradas intermedias
);
```

---

### 🗺️ Nominatim - Geocoding (GRATIS)

#### Buscar Dirección
```dart
final results = await NominatimService.searchAddress('Carrera 7, Bogotá');

for (var result in results) {
  print('${result.displayName} - (${result.lat}, ${result.lon})');
}
```

#### Reverse Geocoding
```dart
final result = await NominatimService.reverseGeocode(4.6097, -74.0817);
print('Dirección: ${result?.getFormattedAddress()}');
```

---

### 🚦 TomTom - Información de Tráfico

#### Flujo de Tráfico
```dart
final traffic = await TrafficService.getTrafficFlow(
  location: LatLng(4.6097, -74.0817),
);

print('Velocidad actual: ${traffic?.currentSpeed} km/h');
print('Velocidad libre: ${traffic?.freeFlowSpeed} km/h');
print('Estado: ${traffic?.description}');
```

#### Incidentes de Tráfico
```dart
final incidents = await TrafficService.getTrafficIncidents(
  location: LatLng(4.6097, -74.0817),
  radiusKm: 5.0,
);

for (var incident in incidents) {
  print('${incident.icon} ${incident.description}');
}
```

---

## 📊 Sistema de Monitoreo de Cuotas

### Características

✅ **Monitoreo Automático** - Rastrea cada solicitud a las APIs  
✅ **Alertas Inteligentes** - Notifica al 50%, 75% y 90% del límite  
✅ **Reset Automático** - Se reinicia mensualmente (Mapbox) y diariamente (TomTom)  
✅ **UI Profesional** - Widget visual con indicadores de progreso  

### Usar el Widget de Alertas

```dart
// En tu pantalla principal
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Tu contenido...
        
        // Widget de alertas (se muestra solo si hay alertas)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: QuotaAlertWidget(compact: false),
        ),
      ],
    ),
  );
}
```

### Actualizar Estado de Cuotas

```dart
final mapProvider = Provider.of<MapProvider>(context, listen: false);
await mapProvider.updateQuotaStatus();
```

### Verificar Manualmente

```dart
final status = await QuotaMonitorService.getQuotaStatus();

print('Mapbox Tiles: ${status.mapboxTilesUsed} / ${status.mapboxTilesLimit}');
print('Mapbox Routing: ${status.mapboxRoutingUsed} / ${status.mapboxRoutingLimit}');
print('TomTom Traffic: ${status.tomtomTrafficUsed} / ${status.tomtomTrafficLimit}');

if (status.hasAlert) {
  print('⚠️ ${status.alertMessage}');
}
```

---

## 🎨 Personalización

### Cambiar Estilo de Mapa

En `env_config.dart`:

```dart
// Estilos disponibles
static const String mapboxStyleStreets = 'streets-v12';    // Calles (default)
static const String mapboxStyleDark = 'dark-v11';          // Oscuro
static const String mapboxStyleLight = 'light-v11';        // Claro
static const String mapboxStyleOutdoors = 'outdoors-v12';  // Exterior
static const String mapboxStyleSatellite = 'satellite-streets-v12'; // Satélite
```

### Ajustar Umbrales de Alerta

```dart
// En env_config.dart
static const double warningThreshold = 0.5;   // 50% - Amarillo
static const double dangerThreshold = 0.75;   // 75% - Naranja
static const double criticalThreshold = 0.9;  // 90% - Rojo
```

---

## 🐛 Solución de Problemas

### Error: "Invalid access token"

**Causa:** Token de Mapbox inválido o expirado

**Solución:**
1. Verifica que el token en `env_config.dart` sea correcto
2. Asegúrate de que el token no tenga espacios extra
3. Regenera el token en Mapbox si es necesario

### Error: "TomTom API Key no configurada"

**Causa:** No has configurado TomTom (opcional)

**Solución:**
- Si no necesitas información de tráfico, puedes ignorarlo
- Si lo necesitas, obtén una key gratuita en TomTom Developer Portal

### Tiles del mapa no cargan

**Causa:** Problema de conectividad o límite de cuotas

**Solución:**
1. Verifica tu conexión a internet
2. Revisa el widget de alertas para ver si superaste el límite
3. Espera al reset mensual o actualiza tu plan

---

## 📈 Límites y Recomendaciones

### Plan Gratuito de Mapbox

| Tipo | Límite Mensual | Recomendación |
|------|----------------|---------------|
| Tiles de Mapa | 100,000 | ~3,300 por día |
| Direcciones | 100,000 | ~3,300 por día |
| Geocoding | 100,000 | Usa Nominatim |

### Plan Gratuito de TomTom

| Tipo | Límite Diario | Recomendación |
|------|---------------|---------------|
| Traffic Flow | 2,500 | Consulta solo cuando sea necesario |
| Traffic Incidents | 2,500 | Cachea resultados por 5-10 min |

### Nominatim (OSM)

- **Límite:** Sin límite oficial, máx. 1 req/seg
- **Recomendación:** Usa para geocoding en lugar de Mapbox
- **Política de uso:** [Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)

---

## 📚 Documentación Adicional

- [Mapbox Documentation](https://docs.mapbox.com/)
- [Mapbox Pricing](https://www.mapbox.com/pricing)
- [TomTom Traffic API](https://developer.tomtom.com/traffic-api/documentation)
- [Nominatim API](https://nominatim.org/release-docs/latest/api/Overview/)

---

## 🤝 Contribuir

Si encuentras algún problema o tienes sugerencias, no dudes en:
1. Reportar un issue
2. Enviar un pull request
3. Contactar al equipo de desarrollo

---

## ✅ Checklist de Configuración

- [x] Token de Mapbox configurado
- [ ] Token de TomTom configurado (opcional)
- [x] `env_config.dart` en `.gitignore`
- [x] Dependencias instaladas (`flutter pub get`)
- [ ] Primera prueba de mapa exitosa
- [ ] Widget de alertas visible
- [ ] Ruta calculada correctamente

---

**¡Listo! 🎉** Tu proyecto ahora usa Mapbox para mapas y rutas, Nominatim para geocoding, y TomTom para tráfico, todo con monitoreo inteligente de cuotas.
