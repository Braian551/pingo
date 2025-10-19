# 🚀 Inicio Rápido - Mapbox Integration

## ⚡ TL;DR - Para Empezar YA

Tu proyecto ya está **100% configurado** con:
- ✅ Token de Mapbox activo
- ✅ APIs gratuitas integradas
- ✅ Sistema de monitoreo de cuotas
- ✅ Widgets listos para usar

### 🎯 Para Probar Inmediatamente

```bash
flutter pub get
flutter run
```

---

## 🗺️ Usar el Mapa con Mapbox

### En cualquier pantalla:

```dart
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

// 1. Usar el widget de mapa
OSMMapWidget(
  initialLocation: LatLng(4.6097, -74.0817),
  interactive: true,
  showMarkers: true,
)

// 2. Mostrar alertas de cuotas
QuotaAlertWidget(compact: true)

// 3. Calcular una ruta
final mapProvider = Provider.of<MapProvider>(context);
await mapProvider.calculateRoute(
  origin: LatLng(4.6097, -74.0817),
  destination: LatLng(6.2476, -75.5658),
);

// 4. Ver información de la ruta
print(mapProvider.currentRoute?.formattedDistance);
print(mapProvider.currentRoute?.formattedDuration);
```

---

## 📱 Pantalla de Ejemplo Completa

Ya está creada en:
```
lib/src/features/map/presentation/screens/map_example_screen.dart
```

Para usarla, añade la ruta en `app_router.dart`:

```dart
case '/map-example':
  return MaterialPageRoute(
    builder: (_) => const MapExampleScreen(),
    settings: settings,
  );
```

Y navega:
```dart
Navigator.pushNamed(context, '/map-example');
```

---

## 🔑 Tu Token de Mapbox

**Ya está configurado:**
```
pk.eyJ1IjoiYnJhaW5waW5nbzIiLCJhIjoiY21neHYzYnF3MWprMTJ3cHU4M3kzeHM1aiJ9.ICn4bFPZVRHcf2fyW7qBEA
```

**Ubicación:**
```
lib/src/core/config/env_config.dart
```

⚠️ **Este archivo NO se sube a Git** (protegido por .gitignore)

---

## 🎨 Características Principales

### 1. Mapas con Mapbox
```dart
// El widget OSMMapWidget ahora usa Mapbox automáticamente
OSMMapWidget(
  initialLocation: LatLng(4.6097, -74.0817),
  interactive: true,
)
```

### 2. Rutas Optimizadas
```dart
await mapProvider.calculateRoute(
  origin: puntoA,
  destination: puntoB,
  waypoints: [punto1, punto2], // Opcional
  profile: 'driving', // driving, walking, cycling
);
```

### 3. Geocoding (GRATIS con Nominatim)
```dart
// Buscar dirección
final results = await NominatimService.searchAddress('Carrera 7, Bogotá');

// Reverse geocoding
final address = await NominatimService.reverseGeocode(4.6097, -74.0817);
```

### 4. Tráfico en Tiempo Real (TomTom - Opcional)
```dart
await mapProvider.fetchTrafficInfo(location);
print(mapProvider.currentTraffic?.description);
```

### 5. Alertas de Cuotas
```dart
// Se muestra automáticamente cuando superas el 50%
QuotaAlertWidget(compact: false)
```

---

## 📊 Monitoreo de Uso

### Ver Estado Actual
```dart
await mapProvider.updateQuotaStatus();
final status = mapProvider.quotaStatus;

print('Uso de Mapbox: ${(status.mapboxTilesPercentage * 100).toInt()}%');
```

### Widget de Estado
```dart
// Badge compacto en AppBar
QuotaStatusBadge()

// Alerta completa
QuotaAlertWidget(compact: false)
```

---

## 🎯 Límites Gratuitos

| API | Límite | Reset |
|-----|--------|-------|
| Mapbox Mapas | 100,000/mes | Mensual |
| Mapbox Rutas | 100,000/mes | Mensual |
| Nominatim | Ilimitado* | - |
| TomTom Tráfico | 2,500/día | Diario |

*Nominatim recomienda máx. 1 request/segundo

---

## 📖 Documentación Completa

- **Configuración detallada:** `MAPBOX_SETUP.md`
- **Resumen de cambios:** `CAMBIOS_MAPBOX.md`
- **Código ejemplo:** `map_example_screen.dart`

---

## ✅ Verificación Rápida

```bash
# 1. Dependencias instaladas
flutter pub get

# 2. Token configurado
# Verifica que existe: lib/src/core/config/env_config.dart

# 3. Protegido de Git
# Verifica que está en .gitignore

# 4. Prueba el mapa
flutter run
# Navega a MapExampleScreen
```

---

## 🆘 Problemas Comunes

### Mapa no carga
✅ Verifica conexión a internet  
✅ Confirma que el token es válido  
✅ Revisa las alertas de cuotas  

### Error de compilación
```bash
flutter clean
flutter pub get
flutter run
```

---

## 💡 Consejos Pro

1. **Cachea geocoding:** Guarda direcciones ya buscadas
2. **Usa Nominatim:** Es gratis para geocoding
3. **Monitorea cuotas:** Revisa el widget regularmente
4. **TomTom opcional:** Solo si necesitas tráfico

---

## 🎉 ¡Listo!

Tu app ahora tiene:
- ✅ Mapas profesionales con Mapbox
- ✅ Rutas optimizadas y navegación
- ✅ Geocoding gratuito ilimitado
- ✅ Monitoreo inteligente de cuotas
- ✅ UI profesional con alertas

**¡Sin cargos inesperados!** 🎊
