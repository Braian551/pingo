# Configuración de Entornos - PinGo

Este documento describe cómo configurar la aplicación PinGo para diferentes entornos: **Local (Laragon)** y **Producción (Railway)**.

---

## 📋 Índice

1. [Entorno Local con Laragon](#entorno-local-con-laragon)
2. [Entorno de Producción](#entorno-de-producción)
3. [Cambiar entre Entornos](#cambiar-entre-entornos)
4. [Estructura de Rutas](#estructura-de-rutas)
5. [Configuración de Base de Datos](#configuración-de-base-de-datos)
6. [Checklist de Despliegue](#checklist-de-despliegue)

---

## 🏠 Entorno Local con Laragon

### Requisitos
- **Laragon** instalado (con Apache + MySQL + PHP)
- **Base de datos**: `pingo`
- **Puerto MySQL**: 3306
- **Credenciales**: root / root

### Configuración del Backend

#### 1. Base de Datos Local (`backend-deploy/config/database.php`)

```php
public function __construct() {
    // Configuración local Laragon
    $this->host = 'localhost';
    $this->db_name = 'pingo';
    $this->username = 'root';
    $this->password = 'root';
}
```

#### 2. Ubicación del Backend en Laragon

Coloca la carpeta `backend-deploy` en:
```
C:\laragon\www\ping_go\backend-deploy
```

La URL de acceso será:
```
http://localhost/ping_go/backend-deploy
```

### Configuración de Flutter

#### 1. Archivo `lib/src/global/config/api_config.dart`

```dart
class ApiConfig {
  // URL base del servidor - Laragon local
  static const String baseUrl = 'http://localhost/ping_go/backend-deploy';
  
  // Endpoints principales
  static const String authEndpoint = '$baseUrl/auth';
  static const String userEndpoint = '$baseUrl/user';
  static const String conductorEndpoint = '$baseUrl/conductor';
  static const String adminEndpoint = '$baseUrl/admin';
}
```

#### 2. Archivo `lib/src/core/config/app_config.dart`

```dart
class AppConfig {
  // Ambiente actual
  static const Environment environment = Environment.development;

  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost/ping_go/backend-deploy'; // Laragon local
      case Environment.production:
        return 'https://pinggo-backend-production.up.railway.app';
    }
  }
}
```

### Consideraciones para Diferentes Dispositivos

| Dispositivo | URL a usar |
|-------------|------------|
| **Navegador Web** (Chrome/Edge) | `http://localhost/ping_go/backend-deploy` |
| **Emulador Android** | `http://10.0.2.2/ping_go/backend-deploy` |
| **Dispositivo físico** | `http://192.168.X.X/ping_go/backend-deploy` (IP de tu PC) |

> **Nota**: Para dispositivo físico, obtén tu IP con `ipconfig` en PowerShell y busca la IPv4.

---

## 🚀 Entorno de Producción

### Configuración del Backend en Railway

#### 1. Base de Datos Remota (`backend-deploy/config/database.php`)

```php
public function __construct() {
    // Free SQL Database credentials (o tu proveedor)
    $this->host = 'sql10.freesqldatabase.com';
    $this->db_name = 'sql10805022';
    $this->username = 'sql10805022';
    $this->password = 'BVeitwKy1q';
}
```

#### 2. URL de Producción

```
https://pinggo-backend-production.up.railway.app
```

### Configuración de Flutter

#### 1. Archivo `lib/src/global/config/api_config.dart`

```dart
class ApiConfig {
  // URL base del servidor - Railway backend
  static const String baseUrl = 'https://pinggo-backend-production.up.railway.app';
  
  static const String authEndpoint = '$baseUrl/auth';
  static const String userEndpoint = '$baseUrl/user';
  static const String conductorEndpoint = '$baseUrl/conductor';
  static const String adminEndpoint = '$baseUrl/admin';
}
```

#### 2. Archivo `lib/src/core/config/app_config.dart`

```dart
class AppConfig {
  // Ambiente actual
  static const Environment environment = Environment.production;

  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost/ping_go/backend-deploy';
      case Environment.production:
        return 'https://pinggo-backend-production.up.railway.app';
    }
  }
}
```

---

## 🔄 Cambiar entre Entornos

### Proceso Rápido de Cambio

#### LOCAL → PRODUCCIÓN

1. **Backend** (`backend-deploy/config/database.php`):
   - Cambiar credenciales de `localhost/root/root/pingo` a credenciales remotas

2. **Flutter** (`lib/src/core/config/app_config.dart`):
   - Cambiar `Environment.development` a `Environment.production`

3. **Flutter** (`lib/src/global/config/api_config.dart`):
   - Cambiar `http://localhost/ping_go/backend-deploy` a `https://pinggo-backend-production.up.railway.app`

#### PRODUCCIÓN → LOCAL

1. **Backend** (`backend-deploy/config/database.php`):
   - Cambiar credenciales remotas a `localhost/root/root/pingo`

2. **Flutter** (`lib/src/core/config/app_config.dart`):
   - Cambiar `Environment.production` a `Environment.development`

3. **Flutter** (`lib/src/global/config/api_config.dart`):
   - Cambiar URL de Railway a `http://localhost/ping_go/backend-deploy`

---

## 📁 Estructura de Rutas

### Endpoints Principales

Todos los endpoints siguen la estructura: `{baseUrl}/{modulo}/{acción}.php`

#### Autenticación (`/auth`)
```
POST {baseUrl}/auth/login.php
POST {baseUrl}/auth/register.php
POST {baseUrl}/auth/verify_code.php
GET  {baseUrl}/auth/profile.php
PUT  {baseUrl}/auth/profile_update.php
```

#### Usuario (`/user`)
```
POST {baseUrl}/user/create_trip_request.php
GET  {baseUrl}/user/find_nearby_drivers.php
POST {baseUrl}/user/cancel_trip_request.php
GET  {baseUrl}/user/get_trip_status.php
```

#### Conductor (`/conductor`)
```
GET  {baseUrl}/conductor/get_pending_requests.php
POST {baseUrl}/conductor/accept_trip_request.php
POST {baseUrl}/conductor/reject_trip_request.php
GET  {baseUrl}/conductor/get_profile.php
PUT  {baseUrl}/conductor/update_profile.php
POST {baseUrl}/conductor/update_location.php
GET  {baseUrl}/conductor/get_estadisticas.php
GET  {baseUrl}/conductor/get_ganancias.php
POST {baseUrl}/conductor/submit_verification.php
POST {baseUrl}/conductor/upload_documents.php
```

#### Admin (`/admin`)
```
GET  {baseUrl}/admin/dashboard_stats.php
GET  {baseUrl}/admin/user_management.php
GET  {baseUrl}/admin/get_conductores_documentos.php
POST {baseUrl}/admin/aprobar_conductor.php
POST {baseUrl}/admin/rechazar_conductor.php
GET  {baseUrl}/admin/audit_logs.php
```

### Ejemplo de Uso en Flutter

```dart
// Usando AppConfig (recomendado)
final url = '${AppConfig.authServiceUrl}/login.php';

// Usando ApiConfig
final url = '${ApiConfig.authEndpoint}/login.php';

// Manual
final url = 'http://localhost/ping_go/backend-deploy/auth/login.php';
```

---

## 💾 Configuración de Base de Datos

### Local (Laragon)

| Parámetro | Valor |
|-----------|-------|
| **Host** | localhost |
| **Puerto** | 3306 |
| **Base de datos** | pingo |
| **Usuario** | root |
| **Contraseña** | root |

### Importar Base de Datos

1. Abre **HeidiSQL** (incluido en Laragon) o phpMyAdmin
2. Crea la base de datos `pingo`
3. Importa el archivo SQL:
   ```
   c:\Flutter\ping_go\basededatos (2).sql
   ```

### Migraciones

Las migraciones están en `backend-deploy/migrations/`:
```
001_create_admin_tables.sql
002_conductor_fields.sql
003_fix_usuarios_columns.sql
004_fix_fecha_creacion_columns.sql
005_add_vehicle_registration_fields.sql
006_add_documentos_conductor.sql
007_create_configuracion_precios.sql
```

Ejecutar en orden según sea necesario.

---

## ✅ Checklist de Despliegue

### Para trabajar LOCAL

- [ ] Laragon iniciado (Apache + MySQL)
- [ ] Base de datos `pingo` creada e importada
- [ ] Backend en `C:\laragon\www\ping_go\backend-deploy`
- [ ] `database.php` → localhost/root/root/pingo
- [ ] `app_config.dart` → Environment.development
- [ ] `api_config.dart` → http://localhost/ping_go/backend-deploy
- [ ] Verificar conexión: `http://localhost/ping_go/backend-deploy/health.php`

### Para desplegar a PRODUCCIÓN

- [ ] Base de datos remota configurada
- [ ] Backend subido a Railway/servidor
- [ ] `database.php` → credenciales remotas
- [ ] `app_config.dart` → Environment.production
- [ ] `api_config.dart` → URL de producción
- [ ] Verificar conexión: `https://pinggo-backend-production.up.railway.app/health.php`
- [ ] Probar endpoints principales
- [ ] Verificar CORS si es necesario

---

## 🔧 Solución de Problemas

### Error de Conexión a Base de Datos

**Local:**
- Verificar que Laragon esté corriendo
- Verificar credenciales en `database.php`
- Verificar que la base `pingo` exista

**Producción:**
- Verificar credenciales remotas
- Verificar que el host remoto esté accesible
- Verificar límites de conexiones del proveedor

### Error 404 en Endpoints

**Local:**
- Verificar que la ruta en Laragon sea correcta: `C:\laragon\www\ping_go\backend-deploy`
- Verificar URL en Flutter: `http://localhost/ping_go/backend-deploy`
- Probar acceder directamente al navegador

**Producción:**
- Verificar que los archivos estén desplegados correctamente
- Verificar la URL base en Flutter

### Error de CORS

Si trabajas con web, agrega en tus archivos PHP:
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
```

---

## 📞 Contacto

Para más información, revisa:
- `docs/DEPLOYMENT.md` - Guía de despliegue completa
- `docs/INDEX.md` - Índice general de documentación
- `backend-deploy/README.md` - Información del backend

---

**Última actualización**: Noviembre 2025
