# 🚀 PingGo - App de Transporte

Aplicación Flutter completa para servicios de transporte con backend PHP/MySQL, mapas interactivos y sistema de verificación por email.

## ✅ Estado del Proyecto

### 🎯 **Funcionalidades Implementadas**
- ✅ **Autenticación completa** (Registro/Login con validaciones)
- ✅ **Verificación por email** (Códigos de 6 dígitos)
- ✅ **Mapas interactivos** (Flutter Map + Mapbox Tiles)
- ✅ **Geolocalización** (GPS en tiempo real)
- ✅ **Geocoding** (Dirección ↔ Coordenadas)
- ✅ **Cálculo de rutas** (Mapbox Directions API)
- ✅ **Información de tráfico** (TomTom API)
- ✅ **Backend PHP/MySQL** (Desplegado en Railway)
- ✅ **Base de datos MySQL** (Railway - sql10.freesqldatabase.com)
- ✅ **UI/UX profesional** (Diseño minimalista)
- ✅ **Panel de administración** (Dashboard completo)

### 🏗️ **Arquitectura Actual**
```
Frontend (Flutter)
├── Autenticación con verificación por email
├── Mapas interactivos con geocoding
├── GPS y cálculo de rutas
└── UI/UX profesional

Backend (PHP + MySQL - Railway)
├── API REST completa
├── Sistema de verificación por email
├── Gestión de usuarios y conductores
├── Panel de administración
└── Base de datos MySQL en la nube
```

### 🚀 **Despliegue**
- **Frontend**: Compilación manual (APK/AAB)
- **Backend**: Railway (https://pinggo-backend-production.up.railway.app)
- **Base de datos**: MySQL en Railway (sql10.freesqldatabase.com)
- **Email**: PHPMailer con Gmail SMTP

## 🚀 Inicio Rápido

### 1. **Instalar Dependencias**
```bash
flutter pub get
```

### 2. **Configurar APIs y Backend**
- ✅ **Mapbox**: Token configurado en `lib/src/core/config/env_config.dart`
- ✅ **TomTom**: Token configurado (opcional)
- ✅ **Nominatim**: Sin configuración requerida
- ✅ **Backend**: URLs configuradas en `lib/src/core/constants/app_constants.dart`
- ✅ **Base de datos**: Conexión MySQL en Railway

### 3. **Ejecutar**
```bash
# Desarrollo
flutter run

# Build de producción
flutter build apk --release
flutter build appbundle --release
```

## 📊 **APIs y Servicios**

| Servicio | Límite Gratuito | Estado | URL |
|----------|----------------|--------|-----|
| **Mapbox Tiles** | 100k/mes | ✅ Activo | mapbox.com |
| **Mapbox Routes** | 100k/mes | ✅ Activo | api.mapbox.com |
| **TomTom Traffic** | 2.5k/día | ✅ Activo | api.tomtom.com |
| **Nominatim** | Ilimitado | ✅ Activo | nominatim.openstreetmap.org |
| **Backend API** | - | ✅ Activo | pinggo-backend-production.up.railway.app |
| **MySQL Database** | - | ✅ Activo | sql10.freesqldatabase.com |
| **Email Service** | - | ✅ Activo | Gmail SMTP |

### 🔧 **URLs de Producción**
```dart
// Backend URLs (lib/src/core/constants/app_constants.dart)
const String baseUrl = 'https://pinggo-backend-production.up.railway.app';
const String verifySystemUrl = '$baseUrl/verify_system_json.php';

// Database connection (Railway)
host: 'sql10.freesqldatabase.com'
database: 'sql10740070'
username: 'sql10740070'
password: '********'
```

## 🛠️ **Problemas Resueltos**

### ✅ **Error Mapbox SDK Registry Token**
- **Problema**: `mapbox_maps_flutter` causaba errores de compilación
- **Solución**: Removido, usando `flutter_map` que funciona perfectamente
- **Resultado**: Todas las funcionalidades de mapas activas

Ver: [SOLUCION_MAPBOX_ERROR.md](docs/SOLUCION_MAPBOX_ERROR.md)

## 📁 **Estructura del Proyecto**

```
lib/
├── src/
│   ├── core/                 # Configuración central
│   │   ├── config/          # Configuración de APIs
│   │   ├── constants/       # URLs y constantes
│   │   └── providers/       # Providers globales
│   ├── features/            # Funcionalidades principales
│   │   ├── auth/           # Autenticación y registro
│   │   ├── home/           # Pantalla principal
│   │   ├── map/            # Mapas y navegación
│   │   ├── onboarding/     # Tutorial inicial
│   │   └── user/           # Perfil de usuario
│   └── global/             # Servicios globales
├── main.dart               # Punto de entrada
└── ...

backend-deploy/             # Backend PHP (Railway)
├── auth/                   # Endpoints de autenticación
├── config/                 # Configuración de BD
├── conductor/              # Gestión de conductores
├── user/                   # Gestión de usuarios
├── admin/                  # Panel de administración
└── vendor/                 # Dependencias PHP

docs/                       # Documentación completa
├── admin/                  # Panel de administración
├── architecture/           # Arquitectura del sistema
├── conductor/              # Funcionalidades de conductor
├── general/                # Utilidades generales
├── home/                   # Pantalla principal
├── mapbox/                 # Configuración de mapas
├── onboarding/             # Tutorial
└── user/                   # Usuario y autenticación
```

## 🎨 **Características de UI/UX**

### ✨ **Registro Mejorado**
- **Stepper visual** con animaciones suaves
- **Pin de ubicación** estilo Uber profesional
- **Animaciones fluidas** y feedback visual
- **Diseño minimalista** consistente

### 🗺️ **Mapa Interactivo**
- **Pin profesional** con animación de pulso
- **Búsqueda inteligente** con resultados en tiempo real
- **Tarjeta inferior** con efecto glass
- **Feedback visual** en cada interacción

## 🔧 **Stack Tecnológico**

### 📱 **Frontend (Flutter)**
- **Flutter** 3.35.3+
- **Dart** 3.0+
- **flutter_map** (Mapas interactivos)
- **geolocator** (GPS)
- **geocoding** (Dirección ↔ Coordenadas)
- **http** (API calls)
- **provider** (State management)

### 🖥️ **Backend (PHP/MySQL)**
- **PHP** 8.3+ (Railway)
- **MySQL** 8.0+ (Railway)
- **PHPMailer** (Envío de emails)
- **Composer** (Gestión de dependencias)

### 🗄️ **Base de Datos**
- **MySQL** (sql10.freesqldatabase.com)
- **Railway** (Hosting cloud)
- **phpMyAdmin** (Gestión de BD)

### 🗺️ **APIs de Mapas**
- **Mapbox** (Tiles y rutas)
- **TomTom** (Tráfico)
- **Nominatim** (Geocoding gratuito)

### 📧 **Email Service**
- **Gmail SMTP** (Envío de emails)
- **PHPMailer** (Librería PHP)
- **Códigos de verificación** (6 dígitos)

## 📚 **Documentación**

### 🏗️ **Arquitectura y Desarrollo**
- [🏛️ Arquitectura del Sistema](docs/architecture/INDEX.md)
- [🧹 Clean Architecture](docs/architecture/CLEAN_ARCHITECTURE.md)
- [🔄 Migración a Microservicios](docs/architecture/MIGRATION_TO_MICROSERVICES.md)
- [✅ Migración Completada](docs/architecture/MIGRATION_COMPLETED.md)

### 🗺️ **Mapas y APIs**
- [📋 Configuración Mapbox](docs/mapbox/MAPBOX_SETUP.md)
- [✅ Implementación Completada](docs/mapbox/IMPLEMENTACION_COMPLETADA.md)
- [🚨 Solución Error Mapbox](docs/SOLUCION_MAPBOX_ERROR.md)

### 👤 **Usuario y Autenticación**
- [🎨 Mejoras UI Registro](docs/MEJORAS_UI_REGISTRO.md)
- [📋 Guía Rápida Usuario](docs/user/GUIA_RAPIDA.md)
- [🔄 Sistema de Solicitudes](docs/user/SISTEMA_SOLICITUD_VIAJES.md)

### 🚗 **Conductor**
- [📋 Guía Rápida Conductor](docs/conductor/GUIA_RAPIDA.md)
- [📄 Sistema de Documentos](docs/conductor/SISTEMA_CARGA_DOCUMENTOS.md)
- [🔊 Notificaciones por Sonido](docs/conductor/SISTEMA_NOTIFICACION_SONIDO.md)

### 🏠 **Home y Navegación**
- [🏡 Home Modernization](docs/home/HOME_MODERNIZATION.md)
- [📍 Home Final Update](docs/home/HOME_FINAL_UPDATE.md)

### 👨‍💼 **Panel de Administración**
- [📊 Dashboard Admin](docs/admin/ADMIN_NAVIGATION_UPDATE.md)
- [👥 Gestión de Usuarios](docs/admin/DOCUMENTOS_CONDUCTORES.md)

### 🎯 **Onboarding**
- [📱 Diseño Onboarding](docs/onboarding/ONBOARDING_DESIGN.md)
- [📋 Instrucciones Onboarding](docs/onboarding/ONBOARDING_INSTRUCTIONS.md)

### 🛠️ **Utilidades**
- [💰 Sistema de Precios](docs/IMPLEMENTACION_COMPLETADA_SISTEMA_PRECIOS.md)
- [📋 Comandos Útiles](docs/COMANDOS_UTILES.md)

## 🚀 **Despliegue y Producción**

### 📱 **App Flutter**
```bash
# Build APK
flutter build apk --release

# Build AAB (Google Play)
flutter build appbundle --release

# Instalar en dispositivo
flutter install
```

### 🖥️ **Backend (Railway)**
- **URL**: https://pinggo-backend-production.up.railway.app
- **Estado**: ✅ Desplegado automáticamente
- **Base de datos**: MySQL en Railway
- **Email**: Gmail SMTP configurado

### 🗄️ **Base de Datos**
- **Host**: sql10.freesqldatabase.com
- **Base de datos**: sql10740070
- **Gestión**: phpMyAdmin o MySQL Workbench

### 🔧 **Configuración de Producción**
```dart
// lib/src/core/constants/app_constants.dart
const String baseUrl = 'https://pinggo-backend-production.up.railway.app';

// lib/src/core/config/env_config.dart
const String mapboxAccessToken = 'tu_token_mapbox';
const String tomtomApiKey = 'tu_api_key_tomtom';
```

## 🤝 **Contribuir**

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

### 📋 **Convenciones de Código**
- Usar Clean Architecture
- Documentar nuevas funcionalidades
- Seguir el patrón de carpetas existente
- Probar en múltiples dispositivos

## 📊 **Estado Actual del Proyecto**

### ✅ **Completado**
- Autenticación completa con verificación por email
- Mapas interactivos con geocoding y rutas
- Backend PHP/MySQL desplegado en Railway
- Panel de administración funcional
- UI/UX profesional y responsive
- Sistema de precios implementado
- Documentación completa

### 🚧 **En Desarrollo**
- Sistema de viajes y reservas
- Notificaciones push
- Chat entre usuarios y conductores
- Sistema de calificaciones

### 🎯 **Próximos Pasos**
- Implementar sistema de pagos
- Agregar más funcionalidades de conductor
- Optimizar rendimiento
- Preparar para Google Play Store

## �📄 **Licencia**

Este proyecto está bajo la Licencia MIT.

---

## 🎉 **Proyecto PingGo**

**🚀 Completamente funcional y listo para producción**

### ✅ **Características Principales**
- **App Flutter nativa** con UI/UX profesional
- **Backend robusto** desplegado en Railway
- **Base de datos MySQL** en la nube
- **Sistema de email** con verificación
- **Mapas interactivos** con múltiples APIs
- **Panel de administración** completo
- **Documentación exhaustiva**

### 📞 **Soporte**
- **Repositorio**: https://github.com/Braian551/pingo
- **Backend**: https://github.com/Braian551/pinggo-backend
- **Documentación**: Carpeta `docs/`
- **Estado**: Producción ready

---

**Última actualización**: Octubre 2025  
**Versión**: 1.0.0  
**Estado**: ✅ **PRODUCCIÓN READY**</content>
<parameter name="filePath">c:\Flutter\ping_go\README.md