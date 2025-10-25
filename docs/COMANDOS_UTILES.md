# 🛠️ Comandos Útiles - PingGo

## 🔍 Verificación

### Buscar URLs Hardcodeadas
```powershell
cd c:\Flutter\ping_go
Select-String -Path "lib\**\*.dart" -Pattern "http://10.0.2.2/pingo/backend" -CaseSensitive
```

### Ver Estructura Backend
```powershell
cd c:\Flutter\ping_go\pingo\backend
Get-ChildItem -Recurse -Filter "*.php" | Format-Table FullName
```

### Buscar Imports de AppConfig
```powershell
cd c:\Flutter\ping_go
Select-String -Path "lib\**\*.dart" -Pattern "import.*app_config" -CaseSensitive
```

---

## 🧪 Testing

### Test URLs
```dart
void main() {
  print('Auth: ${AppConfig.authServiceUrl}');
  print('Conductor: ${AppConfig.conductorServiceUrl}');
  print('Admin: ${AppConfig.adminServiceUrl}');
}
```

### Verificar Archivos Movidos
```bash
# Email service debe estar en auth/
ls c:\Flutter\ping_go\pingo\backend\auth\email_service.php

# Verify code debe estar en auth/
ls c:\Flutter\ping_go\pingo\backend\auth\verify_code.php
```

---

## 📦 Backend

### Verificar Servicios
```bash
# Auth service
curl http://localhost/pingo/backend/auth/login.php

# Conductor service  
curl http://localhost/pingo/backend/conductor/get_profile.php?conductor_id=1

# Admin service
curl http://localhost/pingo/backend/admin/dashboard_stats.php?admin_id=1
```

### Logs
```powershell
# Ver logs de PHP
Get-Content C:\xampp\apache\logs\error.log -Tail 50 -Wait
```

---

## 🚀 Flutter

### Limpiar y Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Análisis
```bash
flutter analyze
```

### Tests
```bash
flutter test
```

---

## 🔄 Git

### Ver Cambios
```bash
git status
git diff
```

### Commit
```bash
git add .
git commit -m "🎯 Reorganizar microservicios y centralizar URLs"
```

---

## 📊 Útiles

### Contar Archivos
```powershell
# PHP files
(Get-ChildItem -Path "c:\Flutter\ping_go\pingo\backend" -Recurse -Filter "*.php").Count

# Dart files
(Get-ChildItem -Path "c:\Flutter\ping_go\lib" -Recurse -Filter "*.dart").Count
```

### Tamaño del Proyecto
```powershell
Get-ChildItem -Path "c:\Flutter\ping_go" -Recurse | 
  Measure-Object -Property Length -Sum | 
  Select-Object @{Name="Size(MB)";Expression={[math]::Round($_.Sum/1MB, 2)}}
```

---

## 🔧 Desarrollo

### Hot Reload
```bash
# En terminal de Flutter
r  # hot reload
R  # hot restart  
```

### Ver Logs
```bash
flutter logs
```

### Dispositivos
```bash
flutter devices
flutter emulators
```

---

## 📝 Documentación

### Generar Docs
```bash
dart doc .
```

### Ver Docs
```bash
# Abrir en navegador
start docs/index.html
```

---

## 🎯 Quick Reference

```bash
# Verificar todo está OK
flutter doctor -v

# Limpiar todo
flutter clean && flutter pub get

# Ejecutar app
flutter run

# Ver estructura
tree /F /A
```

---

**Guarda este archivo** para referencia rápida de comandos.
