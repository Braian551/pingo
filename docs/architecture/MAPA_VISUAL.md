# 🗺️ Mapa Visual de la Arquitectura PingGo

## 📊 Visión General

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP (Frontend)                    │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            AppConfig (URLs Centralizadas)             │  │
│  │  • authServiceUrl: /backend/auth                      │  │
│  │  • conductorServiceUrl: /backend/conductor            │  │
│  │  • adminServiceUrl: /backend/admin                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↓                                 │
│  ┌──────────────┬──────────────┬──────────────────────┐    │
│  │ User Feature │Conductor Feat│  Admin Feature       │    │
│  │              │              │                      │    │
│  │ DataSource ──┼──DataSource ─┼─ Service (Legacy)   │    │
│  │ Repository   │  Repository  │                      │    │
│  │ Provider     │  Provider    │  Provider            │    │
│  └──────────────┴──────────────┴──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            ↓ HTTP
┌─────────────────────────────────────────────────────────────┐
│                   BACKEND (PHP Microservices)                │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │  Auth Service  │  │Conductor Service│  │Admin Service │  │
│  │   (/auth)      │  │  (/conductor)   │  │   (/admin)   │  │
│  ├────────────────┤  ├────────────────┤  ├──────────────┤  │
│  │ • login        │  │ • get_profile  │  │ • dashboard  │  │
│  │ • register     │  │ • update       │  │ • users      │  │
│  │ • profile      │  │ • license      │  │ • audit_logs │  │
│  │ • email_svc ✅ │  │ • vehicle      │  │ • app_config │  │
│  │ • verify_code✅│  │ • historial    │  │              │  │
│  │                │  │ • ganancias    │  │              │  │
│  │                │  │ • disponibilidad│ │              │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
│                            ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Shared Config & Database                    │  │
│  │  • config.php                                         │  │
│  │  • database.php                                       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      MySQL Database                          │
│                                                              │
│  • usuarios                    • conductores                 │
│  • direcciones_usuarios        • vehiculos                   │
│  • sesiones                    • licencias                   │
│                                • viajes                      │
│  • admins                      • ganancias                   │
│  • audit_logs                  • estadisticas                │
│  • app_config                                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Flujo de Requests

### Ejemplo: Login de Usuario

```
[Flutter App]
    ↓
AppConfig.authServiceUrl → "http://10.0.2.2/pingo/backend/auth"
    ↓
UserRemoteDataSource.login()
    ↓
POST ${AppConfig.authServiceUrl}/login.php
    ↓
[Backend: auth/login.php]
    ↓
Validar credenciales en DB
    ↓
Respuesta JSON
    ↓
[Flutter] UserRepository procesa
    ↓
UserProvider notifica UI
    ↓
UI actualizada ✅
```

### Ejemplo: Actualizar Perfil Conductor

```
[Flutter App]
    ↓
AppConfig.conductorServiceUrl → "http://10.0.2.2/pingo/backend/conductor"
    ↓
ConductorRemoteDataSource.updateProfile()
    ↓
POST ${AppConfig.conductorServiceUrl}/update_profile.php
    ↓
[Backend: conductor/update_profile.php]
    ↓
Actualizar en tabla conductores
    ↓
Respuesta JSON
    ↓
[Flutter] ConductorRepository procesa
    ↓
ConductorProvider notifica UI
    ↓
UI actualizada ✅
```

---

## 🏗️ Estructura de Archivos

### Backend

```
backend/
│
├── 📁 auth/                     ✅ Microservicio Auth
│   ├── check_user.php
│   ├── email_service.php        ✅ Movido aquí
│   ├── login.php
│   ├── profile.php
│   ├── profile_update.php
│   ├── register.php
│   ├── verify_code.php          ✅ Movido aquí
│   └── README_USER_MICROSERVICE.md
│
├── 📁 conductor/                ✅ Microservicio Conductor
│   ├── actualizar_disponibilidad.php
│   ├── actualizar_ubicacion.php
│   ├── get_estadisticas.php
│   ├── get_ganancias.php
│   ├── get_historial.php
│   ├── get_info.php
│   ├── get_profile.php
│   ├── get_viajes_activos.php
│   ├── submit_verification.php
│   ├── update_license.php
│   ├── update_profile.php
│   ├── update_vehicle.php
│   └── README_CONDUCTOR_MICROSERVICE.md
│
├── 📁 admin/                    ✅ Microservicio Admin
│   ├── app_config.php
│   ├── audit_logs.php
│   ├── dashboard_stats.php
│   ├── user_management.php
│   └── DEBUG_ADMIN.md
│
├── 📁 config/                   🔧 Configuración
│   ├── config.php
│   └── database.php
│
├── 📁 migrations/               📦 Migraciones
│   ├── 001_create_admin_tables.sql
│   ├── 002_conductor_fields.sql
│   └── ...
│
└── README.md                    📚 Documentación
```

### Frontend

```
lib/src/
│
├── 📁 core/
│   ├── config/
│   │   └── app_config.dart      ✅ URLs CENTRALIZADAS
│   └── ...
│
├── 📁 features/
│   │
│   ├── 📁 user/                 ✅ Clean Architecture
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── user_remote_datasource_impl.dart  ← Usa AppConfig
│   │   │   └── repositories/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── 📁 conductor/            ✅ Clean Architecture
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── conductor_remote_datasource_impl.dart  ← Usa AppConfig
│   │   │   └── repositories/
│   │   ├── services/            ⚠️ Legacy (compatibilidad)
│   │   │   ├── conductor_service.dart
│   │   │   ├── conductor_profile_service.dart
│   │   │   └── ...
│   │   └── ...
│   │
│   └── 📁 admin/
│       └── ...
│
└── 📁 global/
    └── services/
        ├── auth/
        │   └── user_service.dart     ⚠️ Legacy (redundante)
        ├── admin/
        │   └── admin_service.dart    ⚠️ Sin DataSource
        └── email_service.dart        ✅ Usa AppConfig
```

---

## 🔄 Migración: Antes vs Después

### Antes (Monolito con URLs Hardcodeadas)

```
┌──────────────────────────────────────────┐
│        Flutter App (Código Legacy)       │
│                                          │
│  • user_service.dart                     │
│    URL: "http://10.0.2.2/.../auth"      │
│                                          │
│  • conductor_service.dart                │
│    URL: "http://10.0.2.2/.../conductor" │
│                                          │
│  • admin_service.dart                    │
│    URL: "http://10.0.2.2/.../admin"     │
│                                          │
│  ... 10+ archivos con URLs duplicadas   │
└──────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────┐
│      Backend (Archivos mezclados)        │
│                                          │
│  /backend/                               │
│    ├── email_service.php    ❌ Suelto   │
│    ├── verify_code.php      ❌ Suelto   │
│    ├── auth/                             │
│    ├── conductor/                        │
│    └── admin/                            │
└──────────────────────────────────────────┘
```

### Después (Microservicios Organizados)

```
┌──────────────────────────────────────────┐
│        Flutter App (Organizado)          │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │       AppConfig (1 lugar)          │ │
│  │  authServiceUrl                    │ │
│  │  conductorServiceUrl               │ │
│  │  adminServiceUrl                   │ │
│  └────────────────────────────────────┘ │
│               ↑                          │
│  Todos los servicios usan AppConfig     │
└──────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────┐
│    Backend (Microservicios Limpios)      │
│                                          │
│  /backend/                               │
│    ├── auth/                   ✅        │
│    │   ├── email_service.php  ✅ Aquí   │
│    │   ├── verify_code.php    ✅ Aquí   │
│    │   └── ...                           │
│    ├── conductor/              ✅        │
│    │   └── ...                           │
│    └── admin/                  ✅        │
│        └── ...                           │
└──────────────────────────────────────────┘
```

---

## 🌍 Ambientes

### Desarrollo
```
AppConfig.environment = Environment.development

baseUrl = "http://10.0.2.2/pingo/backend"
  ↓
authServiceUrl = "http://10.0.2.2/pingo/backend/auth"
conductorServiceUrl = "http://10.0.2.2/pingo/backend/conductor"
adminServiceUrl = "http://10.0.2.2/pingo/backend/admin"
```

### Staging
```
AppConfig.environment = Environment.staging

baseUrl = "https://staging-api.pingo.com"
  ↓
authServiceUrl = "https://staging-api.pingo.com/auth"
conductorServiceUrl = "https://staging-api.pingo.com/conductor"
adminServiceUrl = "https://staging-api.pingo.com/admin"
```

### Producción
```
AppConfig.environment = Environment.production

baseUrl = "https://api.pingo.com"
  ↓
authServiceUrl = "https://api.pingo.com/auth"
conductorServiceUrl = "https://api.pingo.com/conductor"
adminServiceUrl = "https://api.pingo.com/admin"
```

---

## 🚀 Escalamiento Futuro

### Fase Actual: Monolito Modular

```
┌────────────────────────────────────┐
│    Single Server (xampp/apache)    │
│                                    │
│  ├── /auth         (Puerto 80)    │
│  ├── /conductor    (Puerto 80)    │
│  └── /admin        (Puerto 80)    │
│                                    │
│  Single MySQL Database             │
└────────────────────────────────────┘
```

### Fase 2: Microservicios con Gateway

```
┌─────────────────────────────────────────┐
│        API Gateway (nginx/kong)         │
│              Puerto 80/443              │
└─────────────────────────────────────────┘
           ↓           ↓           ↓
    ┌─────────┐  ┌─────────┐  ┌─────────┐
    │  Auth   │  │Conductor│  │  Admin  │
    │ Service │  │ Service │  │ Service │
    │Port 8001│  │Port 8002│  │Port 8003│
    └─────────┘  └─────────┘  └─────────┘
         ↓            ↓            ↓
    ┌─────────┐  ┌─────────┐  ┌─────────┐
    │   DB    │  │   DB    │  │   DB    │
    │  Users  │  │Conductors│ │  Admin  │
    └─────────┘  └─────────┘  └─────────┘
```

### Fase 3: Microservicios Distribuidos

```
┌───────────────────────────────────────────────┐
│         Load Balancer + API Gateway           │
│            (nginx/kong/traefik)               │
└───────────────────────────────────────────────┘
                      ↓
    ┌─────────────────────────────────────────┐
    │    Service Mesh (Istio/Linkerd)         │
    └─────────────────────────────────────────┘
           ↓           ↓           ↓
    ┌─────────┐  ┌─────────┐  ┌─────────┐
    │  Auth   │  │Conductor│  │  Admin  │
    │ x3 pods │  │ x5 pods │  │ x2 pods │
    └─────────┘  └─────────┘  └─────────┘
         ↓            ↓            ↓
    ┌─────────┐  ┌─────────┐  ┌─────────┐
    │  Redis  │  │PostgreSQL│ │PostgreSQL│
    │  Cache  │  │  Master  │ │  Master  │
    └─────────┘  │ + Replicas│ │+ Replicas│
                 └─────────┘  └─────────┘
```

---

## 📊 Tabla de Endpoints

### Auth Service (`/auth`)

| Método | Endpoint | Función |
|--------|----------|---------|
| POST | `/auth/login.php` | Iniciar sesión |
| POST | `/auth/register.php` | Registrar usuario |
| GET | `/auth/profile.php` | Obtener perfil |
| POST | `/auth/profile_update.php` | Actualizar perfil |
| POST | `/auth/check_user.php` | Verificar usuario |
| POST | `/auth/email_service.php` | Enviar código email |
| POST | `/auth/verify_code.php` | Verificar código |

### Conductor Service (`/conductor`)

| Método | Endpoint | Función |
|--------|----------|---------|
| GET | `/conductor/get_profile.php` | Perfil completo |
| POST | `/conductor/update_profile.php` | Actualizar perfil |
| POST | `/conductor/update_license.php` | Actualizar licencia |
| POST | `/conductor/update_vehicle.php` | Actualizar vehículo |
| GET | `/conductor/get_historial.php` | Historial viajes |
| GET | `/conductor/get_ganancias.php` | Ganancias |
| POST | `/conductor/actualizar_disponibilidad.php` | Disponibilidad |

### Admin Service (`/admin`)

| Método | Endpoint | Función |
|--------|----------|---------|
| GET | `/admin/dashboard_stats.php` | Estadísticas |
| GET | `/admin/user_management.php` | Gestión usuarios |
| GET | `/admin/audit_logs.php` | Logs auditoría |
| GET | `/admin/app_config.php` | Configuración |

---

## ✅ Checklist de Verificación

### Backend
- [x] Archivos organizados por microservicio
- [x] Sin archivos PHP sueltos en raíz
- [x] Cada microservicio tiene README
- [x] Config compartido centralizado

### Frontend
- [x] URLs en AppConfig
- [x] DataSources usan AppConfig
- [x] Servicios legacy actualizados
- [x] Sin URLs hardcodeadas

### Documentación
- [x] Guías de uso creadas
- [x] Diagramas visuales
- [x] Ejemplos de código
- [x] Roadmap definido

---

**Última actualización**: Octubre 2025  
**Versión**: 1.0.0  
**Estado**: ✅ Arquitectura limpia y organizada
