# 📦 Estructura del Proyecto - Mapbox Integration

```
ping_go/
│
├── 📚 DOCUMENTACIÓN (ROOT)
│   ├── README_MAPBOX.md          ⭐ README principal actualizado
│   ├── RESUMEN_EJECUTIVO.md      📊 Resumen para gestión
│   ├── INICIO_RAPIDO.md          🚀 Quick start en 5 minutos
│   ├── MAPBOX_SETUP.md           🔧 Guía completa de configuración
│   ├── CAMBIOS_MAPBOX.md         📝 Changelog técnico
│   └── CHEAT_SHEET.md            💡 Referencia rápida
│
├── lib/
│   └── src/
│       │
│       ├── 🔐 core/
│       │   ├── config/
│       │   │   ├── env_config.dart           ⚠️ TOKENS (NO EN GIT)
│       │   │   └── env_config.dart.example   📄 Plantilla para equipo
│       │   └── constants/
│       │       └── app_constants.dart        📐 Constantes generales
│       │
│       ├── 🌐 global/
│       │   └── services/
│       │       ├── 🗺️ mapbox_service.dart
│       │       │   ├── Directions API (rutas)
│       │       │   ├── Matrix API (distancias)
│       │       │   ├── Static Images API
│       │       │   └── Tiles API
│       │       │
│       │       ├── 🌍 nominatim_service.dart
│       │       │   ├── Geocoding (GRATIS)
│       │       │   └── Reverse Geocoding
│       │       │
│       │       ├── 🚦 traffic_service.dart
│       │       │   ├── Traffic Flow
│       │       │   └── Traffic Incidents
│       │       │
│       │       └── 📊 quota_monitor_service.dart
│       │           ├── Contadores automáticos
│       │           ├── Sistema de alertas
│       │           └── Reset automático
│       │
│       ├── 🎯 features/
│       │   └── map/
│       │       ├── providers/
│       │       │   └── map_provider.dart           🧠 Estado del mapa
│       │       │       ├── Geocoding
│       │       │       ├── Routing
│       │       │       ├── Traffic
│       │       │       └── Quota Status
│       │       │
│       │       └── presentation/
│       │           ├── screens/
│       │           │   └── map_example_screen.dart  🎯 Demo completa
│       │           │       ├── Búsqueda
│       │           │       ├── Rutas
│       │           │       ├── Tráfico
│       │           │       └── Alertas
│       │           │
│       │           └── widgets/
│       │               └── osm_map_widget.dart      🗺️ Widget principal
│       │                   ├── Mapbox Tiles
│       │                   ├── Visualización rutas
│       │                   ├── Marcadores
│       │                   └── Incidentes
│       │
│       └── 🎨 widgets/
│           └── quota_alert_widget.dart              ⚠️ Sistema de alertas
│               ├── QuotaAlertWidget (completo)
│               └── QuotaStatusBadge (compacto)
│
└── .gitignore                                       🔒 Protege env_config.dart
```

---

## 🔄 FLUJO DE DATOS

```
┌─────────────────────────────────────────────┐
│              USER INTERFACE                 │
│  (Screens, Widgets, Buttons, Inputs)       │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│            MAP PROVIDER                     │
│         (Estado y Lógica)                   │
│                                             │
│  • selectedLocation                         │
│  • currentRoute                             │
│  • trafficInfo                              │
│  • quotaStatus                              │
└──────┬─────────┬─────────┬─────────┬────────┘
       │         │         │         │
       ▼         ▼         ▼         ▼
   ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
   │ 🗺️  │  │ 🌍  │  │ 🚦  │  │ 📊  │
   │Map  │  │Geo  │  │Traf │  │Quo  │
   │box  │  │cod  │  │fic  │  │ta   │
   └─────┘  └─────┘  └─────┘  └─────┘
     API      API      API    Local
   (Pago)   (Gratis) (Gratis) Store
```

---

## 🎯 RESPONSABILIDADES

### 📱 Presentation Layer
```
Screens/Widgets
    │
    ├─ Recibe input del usuario
    ├─ Muestra información visual
    ├─ Trigger acciones en Provider
    └─ Escucha cambios de estado
```

### 🧠 Provider Layer
```
MapProvider
    │
    ├─ Mantiene estado de la app
    ├─ Coordina servicios
    ├─ Notifica cambios a UI
    └─ Maneja lógica de negocio
```

### ⚙️ Service Layer
```
Services
    │
    ├─ Comunicación con APIs
    ├─ Transformación de datos
    ├─ Caché y optimización
    └─ Manejo de errores
```

### 💾 Data Layer
```
Local Storage (SharedPreferences)
    │
    ├─ Contadores de cuotas
    ├─ Última fecha de reset
    ├─ Configuraciones
    └─ Caché de datos
```

---

## 🔑 ARCHIVOS CLAVE

### 1. env_config.dart ⚠️
```dart
// NO COMMITEAR - Contiene tokens reales
class EnvConfig {
  static const String mapboxPublicToken = 'pk.xxx';
  static const String tomtomApiKey = 'xxx';
}
```

### 2. mapbox_service.dart 🗺️
```dart
// API de Mapbox - Mapas y Rutas
class MapboxService {
  static Future<MapboxRoute?> getRoute(...)
  static Future<MapboxMatrix?> getMatrix(...)
  static String getTileUrl(...)
}
```

### 3. nominatim_service.dart 🌍
```dart
// Geocoding GRATIS
class NominatimService {
  static Future<List<NominatimResult>> searchAddress(...)
  static Future<NominatimResult?> reverseGeocode(...)
}
```

### 4. traffic_service.dart 🚦
```dart
// Información de Tráfico
class TrafficService {
  static Future<TrafficFlow?> getTrafficFlow(...)
  static Future<List<TrafficIncident>> getTrafficIncidents(...)
}
```

### 5. quota_monitor_service.dart 📊
```dart
// Monitoreo de Cuotas
class QuotaMonitorService {
  static Future<void> incrementMapboxTiles(...)
  static Future<void> incrementMapboxRouting(...)
  static Future<QuotaStatus> getQuotaStatus()
}
```

### 6. map_provider.dart 🧠
```dart
// Estado Global del Mapa
class MapProvider extends ChangeNotifier {
  // Geocoding
  Future<void> searchAddress(...)
  Future<bool> geocodeAndSelect(...)
  
  // Routing
  Future<bool> calculateRoute(...)
  void clearRoute()
  
  // Traffic
  Future<void> fetchTrafficInfo(...)
  Future<void> fetchTrafficIncidents(...)
  
  // Quota
  Future<void> updateQuotaStatus()
}
```

### 7. osm_map_widget.dart 🗺️
```dart
// Widget Principal de Mapa
class OSMMapWidget extends StatefulWidget {
  // Ahora usa Mapbox en lugar de OSM
  // Muestra rutas, marcadores, incidentes
}
```

### 8. quota_alert_widget.dart ⚠️
```dart
// Sistema de Alertas Visuales
class QuotaAlertWidget extends StatelessWidget {
  // Alerta completa o compacta
  // Colores según nivel
  // Diálogo con detalles
}
```

---

## 🔄 CICLO DE VIDA

### Inicio de la App
```
1. main.dart
   ├─ Inicializa Providers
   │  └─ MapProvider()
   │
2. App carga
   ├─ Usuario navega a pantalla con mapa
   │
3. MapProvider.updateQuotaStatus()
   ├─ Carga contadores desde SharedPreferences
   └─ Muestra alertas si es necesario
```

### Cuando Usuario Busca Dirección
```
1. Usuario escribe en TextField
   │
2. mapProvider.searchAddress(query)
   ├─ NominatimService.searchAddress()
   │  └─ HTTP GET a Nominatim API
   │
3. mapProvider notifica listeners
   │
4. UI se actualiza con resultados
   │
5. Usuario selecciona resultado
   │
6. mapProvider.selectSearchResult()
   └─ Mapa se centra en ubicación
```

### Cuando Usuario Calcula Ruta
```
1. Usuario selecciona origen y destino
   │
2. mapProvider.calculateRoute()
   ├─ MapboxService.getRoute()
   │  ├─ HTTP GET a Mapbox Directions API
   │  └─ QuotaMonitorService.incrementMapboxRouting()
   │
3. mapProvider._currentRoute = route
   │
4. mapProvider.notifyListeners()
   │
5. OSMMapWidget se redibuja
   └─ Muestra polyline de la ruta
```

### Sistema de Alertas
```
1. Cada request a API
   ├─ QuotaMonitorService.increment...()
   │  └─ SharedPreferences incrementa contador
   │
2. Periódicamente o al cargar
   ├─ mapProvider.updateQuotaStatus()
   │  └─ QuotaMonitorService.getQuotaStatus()
   │
3. Si % > threshold
   ├─ quotaStatus.hasAlert = true
   │
4. QuotaAlertWidget escucha cambios
   └─ Muestra alerta visual automáticamente
```

---

## 📊 MODELOS DE DATOS

### MapboxRoute
```dart
class MapboxRoute {
  final double distance;          // metros
  final double duration;          // segundos
  final List<LatLng> geometry;    // puntos de la ruta
  final List<MapboxStep>? steps;  // instrucciones
  
  String get formattedDistance;   // "15.2 km"
  String get formattedDuration;   // "25 min"
}
```

### NominatimResult
```dart
class NominatimResult {
  final double lat;
  final double lon;
  final String displayName;
  final Map<String, dynamic> address;
  
  String getFormattedAddress();
  String? getCity();
  String? getState();
}
```

### TrafficFlow
```dart
class TrafficFlow {
  final double currentSpeed;      // km/h actual
  final double freeFlowSpeed;     // km/h sin tráfico
  final double confidence;        // 0.0 - 1.0
  final String roadName;
  
  TrafficLevel get trafficLevel;  // free, moderate, slow, congested
  String get description;
  String get color;               // hex color para UI
}
```

### QuotaStatus
```dart
class QuotaStatus {
  final int mapboxTilesUsed;
  final int mapboxTilesLimit;
  final int mapboxRoutingUsed;
  final int mapboxRoutingLimit;
  final int tomtomTrafficUsed;
  final int tomtomTrafficLimit;
  
  double get mapboxTilesPercentage;
  QuotaAlertLevel get mapboxTilesAlertLevel;
  bool get hasAlert;
  String get alertMessage;
}
```

---

## 🎨 CONVENCIONES DE CÓDIGO

### Nombres de Archivos
```
snake_case.dart         // ✅ Correcto
PascalCase.dart         // ❌ Incorrecto
```

### Clases y Constructores
```dart
class MapboxService { }         // ✅ PascalCase
class mapboxService { }         // ❌ Incorrecto
```

### Variables y Funciones
```dart
final currentRoute = ...;       // ✅ camelCase
final CurrentRoute = ...;       // ❌ Incorrecto
```

### Constantes
```dart
static const String apiKey = ...;           // ✅ camelCase
static const String API_KEY = ...;          // ❌ Incorrecto (estilo viejo)
```

### Privados
```dart
class MyClass {
  String _privateField;         // ✅ Prefijo _
  void _privateMethod() { }     // ✅ Prefijo _
}
```

---

## 🔒 SEGURIDAD

### Archivos en .gitignore
```
lib/src/core/config/env_config.dart     ⚠️ Nunca commitear
**/env_config.dart                      ⚠️ Pattern genérico
*.backup                                🗑️ Backups
*.bak                                   🗑️ Backups
```

### Archivos OK para Git
```
lib/src/core/config/env_config.dart.example   ✅ Plantilla
MAPBOX_SETUP.md                               ✅ Docs
CHEAT_SHEET.md                                ✅ Guías
```

---

## 📈 PRÓXIMAS MEJORAS

### Corto Plazo
- [ ] Caché de geocoding en local
- [ ] Histórico de rutas calculadas
- [ ] Favoritos de ubicaciones
- [ ] Export de rutas

### Mediano Plazo
- [ ] Soporte offline de mapas
- [ ] Optimización de múltiples deliveries
- [ ] Análisis de costos de combustible
- [ ] Predicción de tiempos con IA

### Largo Plazo
- [ ] Integración con Waze
- [ ] Realidad aumentada para navegación
- [ ] Compartir rutas en tiempo real
- [ ] Analytics avanzado

---

**🎯 ESTRUCTURA DISEÑADA PARA ESCALABILIDAD Y MANTENIBILIDAD**

**📊 Todo organizado y documentado para tu equipo**
