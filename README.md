# 🚀 PingGo - App de Transporte

Aplicación Flutter para servicios de transporte con mapas interactivos, geocoding y cálculo de rutas.

## ✅ Estado del Proyecto

### 🎯 **Funcionalidades Implementadas**
- ✅ **Autenticación completa** (Registro/Login con validaciones)
- ✅ **Mapas interactivos** (Flutter Map + Mapbox Tiles)
- ✅ **Geolocalización** (GPS en tiempo real)
- ✅ **Geocoding** (Dirección ↔ Coordenadas)
- ✅ **Cálculo de rutas** (Mapbox Directions API)
- ✅ **Información de tráfico** (TomTom API)
- ✅ **Monitoreo de cuotas** (Alertas inteligentes)
- ✅ **Backend MySQL** (Conexión establecida)
- ✅ **UI/UX profesional** (Diseño minimalista)

### 🗺️ **Arquitectura de Mapas**
```
flutter_map + Mapbox Tiles (gratuito hasta 100k/mes)
├── Nominatim (geocoding gratuito)
├── Mapbox Directions (rutas gratuitas)
└── TomTom Traffic (tráfico gratuito)
```

## 🚀 Inicio Rápido

### 1. **Instalar Dependencias**
```bash
flutter pub get
```

### 2. **Configurar APIs**
- ✅ **Mapbox**: Token configurado en `lib/src/core/config/env_config.dart`
- ✅ **TomTom**: Token configurado (opcional)
- ✅ **Nominatim**: Sin configuración requerida

### 3. **Configurar Firebase (Opcional)**
- ✅ **Firebase SDK**: Configurado en `android/`
- ✅ **Keystore**: `android/release-keystore.jks` (contraseña: `Braian8052`)
- 🔄 **Token CI**: Pendiente (ver sección CI/CD)

### 4. **Ejecutar**
```bash
flutter run
```

## 📊 **APIs y Costos**

| Servicio | Límite Gratuito | Estado |
|----------|----------------|--------|
| **Mapbox Tiles** | 100k/mes | ✅ Activo |
| **Mapbox Routes** | 100k/mes | ✅ Activo |
| **TomTom Traffic** | 2.5k/día | ✅ Activo |
| **Nominatim** | Ilimitado | ✅ Activo |

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
│   ├── features/             # Funcionalidades principales
│   │   ├── auth/            # Autenticación
│   │   └── map/             # Mapas y navegación
│   └── global/              # Servicios globales
├── main.dart                # Punto de entrada
└── ...

docs/                        # Documentación completa
├── mapbox/                  # Configuración de mapas
├── SOLUCION_MAPBOX_ERROR.md # Solución al error
└── MEJORAS_UI_REGISTRO.md   # UI/UX mejorado
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

## 🔧 **Tecnologías**

- **Flutter** 3.9.2+
- **Dart** 3.0+
- **MySQL** (Backend)
- **Mapbox** (Mapas y rutas)
- **TomTom** (Tráfico)
- **Nominatim** (Geocoding gratuito)

## 📚 **Documentación**

- [📋 Configuración Mapbox](docs/mapbox/MAPBOX_SETUP.md)
- [✅ Implementación Completada](docs/mapbox/IMPLEMENTACION_COMPLETADA.md)
- [🚨 Solución Error Mapbox](docs/SOLUCION_MAPBOX_ERROR.md)
- [🎨 Mejoras UI Registro](docs/MEJORAS_UI_REGISTRO.md)
- [🚀 Firebase CI/CD Setup](docs/FIREBASE_CI_CD_SETUP.md)

## 🤝 **Contribuir**

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## � **CI/CD - Despliegue Automático**

### ✅ **Configuración Lista**
- ✅ **GitHub Actions**: Workflow creado (`.github/workflows/firebase-deploy.yml`)
- ✅ **Firebase SDK**: Configurado en Android
- ✅ **Keystore**: Configurado para builds firmados

### 🔑 **Configurar Secretos en GitHub**

1. **Generar Token Firebase CI** (en tu máquina local):
   ```bash
   # Instalar Firebase CLI (si no lo tienes)
   npm install -g firebase-tools
   
   # Generar token (abre navegador para autenticación)
   firebase login:ci
   ```

2. **Agregar Secretos en GitHub**:
   - Ve a: `Repositorio → Settings → Secrets and variables → Actions`
   - **FIREBASE_TOKEN**: El token generado arriba
   - **FIREBASE_APP_ID**: ID de tu app Firebase (ej: `1:123456789:android:abc123def456`)

### 🎯 **Cómo Funciona**
- **Push a `main`**: Se ejecuta automáticamente
- **Build APK + AAB**: Ambos formatos generados
- **Despliegue**: Subido a Firebase App Distribution
- **Testers**: Grupo "testers" recibe notificaciones

### 📱 **Distribución**
- **APK**: Para tests internos rápidos
- **AAB**: Para Google Play Store
- **Grupos**: Configurable en Firebase Console

## �📄 **Licencia**

Este proyecto está bajo la Licencia MIT.

---

**🚀 Proyecto completamente funcional**  
**✅ Error de Mapbox resuelto**  
**🎯 Listo para desarrollo y producción**

Última actualización: Octubre 2025</content>
<parameter name="filePath">c:\Flutter\ping_go\README.md