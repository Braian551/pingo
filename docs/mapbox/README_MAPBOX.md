# 📱 PingGo - App de Transporte con Mapbox

> Aplicación de transporte y delivery con integración profesional de mapas usando Mapbox, geocoding gratuito con Nominatim, y sistema inteligente de monitoreo de cuotas.

## ✨ Características Principales

### 🗺️ Sistema de Mapas Avanzado
- **Mapbox Integration** - Mapas profesionales de alta calidad
- **Rutas Optimizadas** - Cálculo de rutas con múltiples waypoints
- **Geocoding Gratuito** - Búsqueda de direcciones ilimitada (Nominatim)
- **Tráfico en Tiempo Real** - Información de flujo e incidentes (TomTom)

### 📊 Monitoreo Inteligente
- **Sistema de Cuotas** - Rastreo automático de uso de APIs
- **Alertas Visuales** - Notificaciones al 50%, 75% y 90% del límite
- **Reset Automático** - Contadores que se reinician según el periodo
- **UI Profesional** - Widgets dedicados para visualización

### 🔐 Seguridad
- **API Keys Protegidas** - Configuración segura sin exposición en Git
- **Variables de Entorno** - Sistema de configuración por ambiente
- **Ejemplo Template** - Plantilla para el equipo de desarrollo

## 🚀 Inicio Rápido

### 1. Clonar e Instalar
```bash
git clone <repository-url>
cd ping_go
flutter pub get
```

### 2. Configurar API Keys

#### Opción A: Usar la configuración actual (Ya lista)
El token de Mapbox ya está configurado en `lib/src/core/config/env_config.dart`

#### Opción B: Crear tu propia configuración
```bash
cp lib/src/core/config/env_config.dart.example lib/src/core/config/env_config.dart
```

Luego edita `env_config.dart` con tus tokens:
```dart
static const String mapboxPublicToken = 'TU_TOKEN_AQUI';
static const String tomtomApiKey = 'TU_KEY_AQUI'; // Opcional
```

### 3. Ejecutar
```bash
flutter run
```

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| [INICIO_RAPIDO.md](INICIO_RAPIDO.md) | Guía rápida para empezar en 5 minutos |
| [MAPBOX_SETUP.md](MAPBOX_SETUP.md) | Configuración completa y detallada |
| [CAMBIOS_MAPBOX.md](CAMBIOS_MAPBOX.md) | Resumen de cambios implementados |

## 🛠️ Tecnologías Utilizadas

### Frontend
- **Flutter** 3.9.2+
- **Provider** - Gestión de estado
- **flutter_map** - Visualización de mapas
- **latlong2** - Manejo de coordenadas

### APIs y Servicios
- **Mapbox** - Mapas y rutas (100k/mes gratis)
- **Nominatim (OSM)** - Geocoding (gratis ilimitado)
- **TomTom** - Tráfico (2.5k/día gratis)

### Backend
- **MySQL** - Base de datos
- **PHP** - API para emails

## 📁 Estructura del Proyecto

```
lib/
├── src/
│   ├── core/
│   │   ├── config/
│   │   │   ├── env_config.dart ⚠️ NO EN GIT
│   │   │   └── env_config.dart.example
│   │   └── constants/
│   │       └── app_constants.dart
│   ├── global/
│   │   └── services/
│   │       ├── mapbox_service.dart         🗺️ Mapas y rutas
│   │       ├── nominatim_service.dart      🌍 Geocoding gratis
│   │       ├── traffic_service.dart        🚦 Tráfico
│   │       └── quota_monitor_service.dart  📊 Monitoreo
│   ├── features/
│   │   ├── auth/
│   │   ├── map/
│   │   │   ├── providers/
│   │   │   │   └── map_provider.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── map_example_screen.dart 🎯 Ejemplo completo
│   │   │       └── widgets/
│   │   │           └── osm_map_widget.dart
│   │   └── ride/
│   └── widgets/
│       └── quota_alert_widget.dart         ⚠️ Alertas de cuotas
└── main.dart
```

## 🎨 Ejemplos de Uso

### Calcular Ruta
```dart
final mapProvider = Provider.of<MapProvider>(context, listen: false);

await mapProvider.calculateRoute(
  origin: LatLng(4.6097, -74.0817),      // Bogotá
  destination: LatLng(6.2476, -75.5658),  // Medellín
  profile: 'driving',
);

print('Distancia: ${mapProvider.currentRoute?.formattedDistance}');
print('Duración: ${mapProvider.currentRoute?.formattedDuration}');
```

### Buscar Dirección (Gratis)
```dart
final results = await NominatimService.searchAddress('Carrera 7, Bogotá');

for (var result in results) {
  print('${result.displayName}');
  print('Lat: ${result.lat}, Lon: ${result.lon}');
}
```

### Mostrar Alertas de Cuotas
```dart
// En tu Scaffold
Stack(
  children: [
    OSMMapWidget(...),
    
    Positioned(
      top: 16,
      right: 16,
      child: QuotaAlertWidget(compact: true),
    ),
  ],
)
```

### Obtener Información de Tráfico
```dart
await mapProvider.fetchTrafficInfo(location);

final traffic = mapProvider.currentTraffic;
print('Estado: ${traffic?.description}');
print('Velocidad: ${traffic?.currentSpeed} km/h');
```

## 📊 Límites y Cuotas

| API | Plan | Límite | Reset |
|-----|------|--------|-------|
| **Mapbox Tiles** | Free | 100,000/mes | Mensual |
| **Mapbox Routing** | Free | 100,000/mes | Mensual |
| **Nominatim** | Free | Ilimitado* | - |
| **TomTom Traffic** | Free | 2,500/día | Diario |

*Nominatim recomienda máximo 1 request por segundo

## 🔧 Configuración de Desarrollo

### Variables de Entorno

Crea `lib/src/core/config/env_config.dart` basado en el ejemplo:

```dart
class EnvConfig {
  // Mapbox (REQUERIDO)
  static const String mapboxPublicToken = 'pk.xxx';
  
  // TomTom (OPCIONAL para tráfico)
  static const String tomtomApiKey = 'xxx';
  
  // Nominatim (NO requiere key)
  static const String nominatimUserAgent = 'PingGo App';
  static const String nominatimEmail = 'tu-email@ejemplo.com';
}
```

### Obtener API Keys

#### Mapbox (Requerido)
1. Visita [Mapbox Account](https://account.mapbox.com/)
2. Crea una cuenta gratuita
3. Genera un Access Token público
4. Copia el token (empieza con `pk.`)

#### TomTom (Opcional)
1. Visita [TomTom Developer](https://developer.tomtom.com/)
2. Registra una cuenta gratuita
3. Crea una aplicación
4. Copia tu API Key

## 🐛 Solución de Problemas

### Mapa no carga
```bash
# 1. Verifica tu conexión
# 2. Confirma que el token de Mapbox es válido
# 3. Revisa las alertas de cuotas
```

### Error de compilación
```bash
flutter clean
flutter pub get
flutter run
```

### API Key inválida
- Verifica que el token comience con `pk.` (Mapbox)
- Asegúrate de no tener espacios extras
- Regenera el token si es necesario

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Reglas de Contribución
- ⚠️ **NUNCA** commitees `env_config.dart` con tokens reales
- ✅ Usa `env_config.dart.example` para documentar nuevas configs
- ✅ Actualiza la documentación con tus cambios
- ✅ Prueba localmente antes de hacer PR

## 📝 Licencia

Este proyecto es privado y confidencial.

## 📞 Contacto

- **Email**: traconmaster@gmail.com
- **GitHub**: [@Braian551](https://github.com/Braian551)

## 🙏 Agradecimientos

- [Mapbox](https://www.mapbox.com/) - Mapas profesionales
- [OpenStreetMap](https://www.openstreetmap.org/) - Datos de mapas abiertos
- [Nominatim](https://nominatim.org/) - Geocoding gratuito
- [TomTom](https://www.tomtom.com/) - Información de tráfico

---

## 🎯 Roadmap

- [x] Integración con Mapbox
- [x] Sistema de monitoreo de cuotas
- [x] Geocoding con Nominatim
- [x] Información de tráfico con TomTom
- [ ] Soporte offline de mapas
- [ ] Historial de rutas
- [ ] Optimización de múltiples destinos
- [ ] Análisis de costos de viaje

---

**¡Desarrollado con ❤️ para PingGo!**
