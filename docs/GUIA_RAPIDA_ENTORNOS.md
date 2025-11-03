# 🚀 Guía Rápida: Cambio de Entornos

**Referencia rápida para cambiar entre desarrollo local (Laragon) y producción (Railway)**

---

## ⚡ Cambio Rápido LOCAL ↔ PRODUCCIÓN

### 📝 Archivos a Modificar (3 archivos)

#### 1️⃣ Backend: `backend-deploy/config/database.php`

```php
// ========================================
// ELEGIR UNO (comentar/descomentar)
// ========================================

// ✅ LOCAL (Laragon)
$this->host = 'localhost';
$this->db_name = 'pingo';
$this->username = 'root';
$this->password = 'root';

// ❌ PRODUCCIÓN (Railway) - comentar para local
// $this->host = 'sql10.freesqldatabase.com';
// $this->db_name = 'sql10805022';
// $this->username = 'sql10805022';
// $this->password = 'BVeitwKy1q';
```

#### 2️⃣ Flutter: `lib/src/core/config/app_config.dart`

```dart
// ========================================
// CAMBIAR SOLO ESTA LÍNEA
// ========================================

// ✅ LOCAL
static const Environment environment = Environment.development;

// ❌ PRODUCCIÓN
// static const Environment environment = Environment.production;
```

#### 3️⃣ Flutter: `lib/src/global/config/api_config.dart`

```dart
// ========================================
// CAMBIAR SOLO ESTA LÍNEA
// ========================================

// ✅ LOCAL
static const String baseUrl = 'http://localhost/ping_go/backend-deploy';

// ❌ PRODUCCIÓN
// static const String baseUrl = 'https://pinggo-backend-production.up.railway.app';
```

---

## 📋 Checklist Rápido

### Configuración LOCAL ✅

- [ ] Backend en `C:\laragon\www\ping_go\backend-deploy`
- [ ] Base de datos `pingo` creada en MySQL
- [ ] SQL importado (`basededatos (2).sql`)
- [ ] `database.php` → localhost/root/root/pingo
- [ ] `app_config.dart` → Environment.development
- [ ] `api_config.dart` → http://localhost/...
- [ ] Laragon corriendo (Apache + MySQL)
- [ ] Verificar: `http://localhost/ping_go/backend-deploy/health.php`

### Configuración PRODUCCIÓN ☁️

- [ ] Backend desplegado en Railway
- [ ] Base de datos remota configurada
- [ ] `database.php` → credenciales remotas
- [ ] `app_config.dart` → Environment.production
- [ ] `api_config.dart` → https://pinggo-backend-production...
- [ ] Verificar: `https://pinggo-backend-production.up.railway.app/health.php`

---

## 🔧 URLs de Verificación

### Local
```
http://localhost/ping_go/backend-deploy/health.php
http://localhost/ping_go/backend-deploy/verify_system_json.php
```

### Producción
```
https://pinggo-backend-production.up.railway.app/health.php
https://pinggo-backend-production.up.railway.app/verify_system_json.php
```

---

## 📱 URLs para Dispositivos (Solo LOCAL)

| Dispositivo | URL |
|-------------|-----|
| **Navegador** | `http://localhost/ping_go/backend-deploy` |
| **Emulador Android** | `http://10.0.2.2/ping_go/backend-deploy` |
| **Dispositivo físico** | `http://[TU_IP]/ping_go/backend-deploy` |

Para obtener tu IP:
```powershell
ipconfig
# Busca IPv4: 192.168.X.X
```

---

## 🚀 Setup Rápido de Local

### Opción 1: Script Automático
```bash
# PowerShell
.\setup_local.ps1

# O Batch
setup_local.bat
```

### Opción 2: Manual
```bash
# 1. Copiar backend
xcopy backend-deploy C:\laragon\www\ping_go\backend-deploy /E /I

# 2. Crear DB y importar SQL en HeidiSQL

# 3. Verificar
http://localhost/ping_go/backend-deploy/health.php
```

---

## 🐛 Problemas Comunes

### ❌ Error de conexión a BD
```php
// Verifica en database.php:
$this->host = 'localhost';  // ✅ Sin puerto
// NO: 'localhost:3306'
```

### ❌ 404 Not Found
```
Verifica la ruta:
C:\laragon\www\ping_go\backend-deploy
                 ^^^^^^^^ importante
```

### ❌ Connection refused en Flutter
```dart
// Para navegador: localhost
// Para emulador: 10.0.2.2
// Para físico: tu IP (192.168.X.X)
```

---

## 📚 Documentación Completa

- **[CONFIGURACION_ENTORNOS.md](CONFIGURACION_ENTORNOS.md)** - Guía detallada
- **[SETUP_LARAGON.md](SETUP_LARAGON.md)** - Setup paso a paso
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Despliegue a producción
- **[RESUMEN_CAMBIOS_LOCAL.md](RESUMEN_CAMBIOS_LOCAL.md)** - Log de cambios

---

## 💡 Tips

### Mantener ambas configuraciones
Puedes dejar comentarios en cada archivo para cambiar rápidamente:

```php
// database.php
// LOCAL: localhost/pingo/root/root
// PRODUCCIÓN: sql10.freesqldatabase.com/...
```

```dart
// api_config.dart
// LOCAL: http://localhost/ping_go/backend-deploy
// PRODUCCIÓN: https://pinggo-backend-production.up.railway.app
```

### Git ignore para configuraciones locales
Considera crear archivos `.env` para credenciales sensibles.

---

**Última actualización**: Noviembre 2025  
**Proyecto**: PinGo - App de Transporte
