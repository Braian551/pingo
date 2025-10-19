# 🎨 CHEAT SHEET - Mapbox + APIs Gratuitas

> Referencia rápida de todo lo que necesitas saber

---

## 🔑 API KEYS

### Mapbox (YA CONFIGURADO)
```dart
// lib/src/core/config/env_config.dart
static const String mapboxPublicToken = 'pk.eyJ1IjoiYnJh...';
```

### TomTom (Opcional)
```dart
static const String tomtomApiKey = 'TU_KEY_AQUI';
```
Obtén en: https://developer.tomtom.com/

---

## 🗺️ USAR MAPA

### Widget Básico
```dart
OSMMapWidget(
  initialLocation: LatLng(4.6097, -74.0817),
  interactive: true,
  showMarkers: true,
)
```

### Con Provider
```dart
final mapProvider = Provider.of<MapProvider>(context);
```

---

## 🚗 CALCULAR RUTAS

### Ruta Simple
```dart
await mapProvider.calculateRoute(
  origin: LatLng(4.6097, -74.0817),
  destination: LatLng(6.2476, -75.5658),
  profile: 'driving', // 'walking', 'cycling'
);
```

### Ver Resultado
```dart
final route = mapProvider.currentRoute;
print(route?.formattedDistance);  // "195.2 km"
print(route?.formattedDuration);  // "3h 15min"
print(route?.geometry);           // List<LatLng>
```

### Limpiar Ruta
```dart
mapProvider.clearRoute();
```

---

## 📍 GEOCODING (GRATIS)

### Buscar Dirección
```dart
final results = await NominatimService.searchAddress('Carrera 7, Bogotá');

for (var result in results) {
  print(result.displayName);
  print('${result.lat}, ${result.lon}');
}
```

### Reverse Geocoding
```dart
final result = await NominatimService.reverseGeocode(4.6097, -74.0817);
print(result?.getFormattedAddress());
print(result?.getCity());
print(result?.getState());
```

### Con Provider
```dart
await mapProvider.geocodeAndSelect('Carrera 7, Bogotá');
final location = mapProvider.selectedLocation;
final address = mapProvider.selectedAddress;
```

---

## 🚦 TRÁFICO

### Flujo de Tráfico
```dart
await mapProvider.fetchTrafficInfo(location);

final traffic = mapProvider.currentTraffic;
print(traffic?.description);      // "Tráfico fluido"
print(traffic?.currentSpeed);     // 45.0 km/h
print(traffic?.freeFlowSpeed);    // 60.0 km/h
print(traffic?.color);            // "#00FF00"
```

### Incidentes
```dart
await mapProvider.fetchTrafficIncidents(
  location,
  radiusKm: 5.0,
);

for (var incident in mapProvider.trafficIncidents) {
  print('${incident.icon} ${incident.description}');
  print('Severidad: ${incident.severityText}');
}
```

---

## 📊 MONITOREO DE CUOTAS

### Actualizar Estado
```dart
await mapProvider.updateQuotaStatus();
```

### Ver Cuotas
```dart
final status = mapProvider.quotaStatus;

print('Mapbox Tiles: ${status.mapboxTilesUsed} / ${status.mapboxTilesLimit}');
print('Porcentaje: ${(status.mapboxTilesPercentage * 100).toInt()}%');

if (status.hasAlert) {
  print('⚠️ ${status.alertMessage}');
}
```

### Reset Manual (para pruebas)
```dart
await QuotaMonitorService.resetAll();
```

---

## 🎨 WIDGETS DE UI

### Alerta Completa
```dart
QuotaAlertWidget(
  compact: false, // false = información completa
)
```

### Alerta Compacta
```dart
QuotaAlertWidget(
  compact: true, // true = versión pequeña
)
```

### Badge en AppBar
```dart
AppBar(
  title: Text('PingGo'),
  actions: [
    QuotaStatusBadge(), // Muestra % de uso
  ],
)
```

---

## 🎯 EJEMPLOS COMUNES

### 1. Buscar y Mostrar Lugar
```dart
// Buscar
final results = await NominatimService.searchAddress(query);

// Seleccionar primero
if (results.isNotEmpty) {
  mapProvider.selectSearchResult(results.first);
}

// El mapa se centra automáticamente
```

### 2. Ruta con Waypoints
```dart
await mapProvider.calculateRoute(
  origin: puntoA,
  destination: puntoD,
  waypoints: [puntoB, puntoC],
  profile: 'driving',
);
```

### 3. Verificar Tráfico Antes de Ruta
```dart
// 1. Obtener tráfico
await mapProvider.fetchTrafficInfo(origen);
final traffic = mapProvider.currentTraffic;

// 2. Decidir según tráfico
if (traffic != null && traffic.trafficLevel == TrafficLevel.congested) {
  print('⚠️ Tráfico congestionado, busca ruta alternativa');
}

// 3. Calcular ruta
await mapProvider.calculateRoute(...);
```

### 4. Pantalla Completa con Todo
```dart
Scaffold(
  body: Stack(
    children: [
      // Mapa
      OSMMapWidget(...),
      
      // Alerta de cuotas
      Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: QuotaAlertWidget(compact: true),
      ),
      
      // Info de ruta
      if (mapProvider.currentRoute != null)
        Positioned(
          bottom: 16,
          child: RouteInfoCard(),
        ),
    ],
  ),
)
```

---

## 🚨 NIVELES DE ALERTA

| % Uso | Nivel | Color | Icono |
|-------|-------|-------|-------|
| 0-50% | Normal | 🟢 Verde | ✅ |
| 50-75% | Warning | 🟡 Amarillo | ⚠️ |
| 75-90% | Danger | 🟠 Naranja | ⚠️ |
| 90-100% | Critical | 🔴 Rojo | ❌ |

---

## 📊 LÍMITES

### Mapbox (Mensual)
- **Tiles:** 100,000
- **Routing:** 100,000
- Reset: 1ro de cada mes

### TomTom (Diario)
- **Traffic:** 2,500
- Reset: Cada día a las 00:00

### Nominatim
- **Ilimitado** (máx. 1 req/seg recomendado)

---

## 🎨 ESTILOS DE MAPA

```dart
// En MapboxService.getTileUrl()
'streets-v12'           // Calles (default)
'dark-v11'              // Oscuro
'light-v11'             // Claro
'outdoors-v12'          // Exterior
'satellite-streets-v12' // Satélite
```

---

## 🔧 CONFIGURACIÓN

### Cambiar Umbrales de Alerta
```dart
// lib/src/core/config/env_config.dart
static const double warningThreshold = 0.5;   // 50%
static const double dangerThreshold = 0.75;   // 75%
static const double criticalThreshold = 0.9;  // 90%
```

### Deshabilitar Monitoreo
```dart
static const bool enableQuotaMonitoring = false;
static const bool showQuotaAlerts = false;
```

---

## 🐛 TROUBLESHOOTING

### Mapa no carga
```dart
// 1. Verifica token
print(EnvConfig.mapboxPublicToken);

// 2. Verifica conexión
// 3. Revisa cuotas
await mapProvider.updateQuotaStatus();
```

### Error "Invalid token"
- Token debe empezar con `pk.`
- Sin espacios ni saltos de línea
- Regenera en: https://account.mapbox.com/

### Geocoding no funciona
```dart
// Nominatim no requiere key
// Solo verifica conexión a internet
```

---

## 🎯 MEJORES PRÁCTICAS

### ✅ DO
- Usar Nominatim para geocoding
- Cachear direcciones buscadas
- Monitorear cuotas regularmente
- Limpiar rutas cuando no se usen

### ❌ DON'T
- No usar Mapbox Geocoding (usa Nominatim)
- No hacer requests innecesarios
- No ignorar alertas de cuotas
- No commitear env_config.dart

---

## 📱 INTEGRACIÓN EN PANTALLAS

### HomeScreen
```dart
// Añade provider
final mapProvider = Provider.of<MapProvider>(context);

// Añade badge
QuotaStatusBadge()

// Botón para abrir mapa
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/map-example'),
  child: Text('Ver Mapa'),
)
```

### AppBar Global
```dart
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.map),
      onPressed: () => Navigator.pushNamed(context, '/map'),
    ),
    QuotaStatusBadge(),
  ],
)
```

---

## 🔗 ENLACES ÚTILES

- **Mapbox Docs:** https://docs.mapbox.com/
- **Mapbox Account:** https://account.mapbox.com/
- **TomTom Portal:** https://developer.tomtom.com/
- **Nominatim Docs:** https://nominatim.org/release-docs/latest/

---

## 📞 AYUDA RÁPIDA

| Problema | Solución |
|----------|----------|
| Mapa negro | Verifica token |
| Sin rutas | Verifica conexión |
| Sin geocoding | Usa Nominatim |
| Alertas constantes | Aumenta límites o reduce uso |

---

**💡 TIP:** Guarda este archivo como referencia rápida

**🚀 Happy Coding!**
