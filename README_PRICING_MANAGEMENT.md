# Gestión de Tarifas y Precios - PinGo Admin

## 📋 Descripción

Nueva funcionalidad para administradores que permite gestionar las tarifas y precios del sistema directamente desde la aplicación móvil.

## ✨ Características

- ✅ Visualización de todas las configuraciones de precios por tipo de vehículo
- ✅ Edición en tiempo real de tarifas base, costos por km/minuto
- ✅ Gestión de recargos (hora pico, nocturno, festivo)
- ✅ Configuración de comisiones de la plataforma
- ✅ Interfaz moderna con diseño glassmorphism
- ✅ Validación de datos antes de guardar
- ✅ Auditoría automática de cambios

## 🎯 Tipos de Vehículo Soportados

1. **Moto** 🏍️
2. **Carro** 🚗
3. **Moto Carga** 📦
4. **Carro Carga** 🚚

## 📱 Acceso en la App

1. Iniciar sesión como **Administrador**
2. Ir a **Gestión** (tab inferior)
3. Seleccionar **"Tarifas y Comisiones"**
4. Ver y editar cualquier configuración

## 🔧 Configuraciones Editables

### Tarifas Básicas
- **Tarifa Base**: Costo fijo inicial del servicio
- **Costo por Km**: Precio por kilómetro recorrido
- **Costo por Minuto**: Precio por minuto de viaje
- **Tarifa Mínima**: Precio mínimo del servicio
- **Tarifa Máxima**: Límite superior del precio (opcional)

### Recargos
- **Hora Pico**: Porcentaje adicional en horas pico (mañana/tarde)
- **Nocturno**: Porcentaje adicional en horario nocturno
- **Festivo**: Porcentaje adicional en días festivos

### Descuentos
- **Descuento Distancia Larga**: Porcentaje de descuento para viajes largos
- **Umbral Km Descuento**: Kilómetros necesarios para aplicar descuento

### Comisiones
- **Comisión Plataforma**: Porcentaje que retiene la plataforma
- **Comisión Método Pago**: Comisión adicional por pagos digitales

### Límites y Espera
- **Distancia Mínima/Máxima**: Rango de distancias permitidas
- **Tiempo Espera Gratis**: Minutos de espera sin cargo
- **Costo Tiempo Espera**: Cargo por minuto adicional de espera

## 🗄️ Base de Datos

### Tabla Principal: `configuracion_precios`

```sql
SELECT * FROM configuracion_precios WHERE activo = 1;
```

Campos principales:
- `id`: Identificador único
- `tipo_vehiculo`: moto, carro, moto_carga, carro_carga
- `tarifa_base`: Decimal(10,2)
- `costo_por_km`: Decimal(10,2)
- `costo_por_minuto`: Decimal(10,2)
- `recargo_hora_pico`: Decimal(5,2)
- `recargo_nocturno`: Decimal(5,2)
- `recargo_festivo`: Decimal(5,2)
- `comision_plataforma`: Decimal(5,2)
- `activo`: Boolean (1 = activo)

### Auditoría: `historial_precios`

Registra automáticamente todos los cambios:
```sql
SELECT * FROM historial_precios ORDER BY fecha_cambio DESC LIMIT 10;
```

## 🔌 Endpoints API

### 1. Obtener Configuraciones
```
GET http://localhost:8000/admin/get_pricing_configs.php
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "tipo_vehiculo": "moto",
      "tarifa_base": 4000.00,
      "costo_por_km": 250.00,
      "costo_por_minuto": 2000.00,
      ...
    }
  ],
  "stats": {
    "total": 8,
    "activos": 4,
    "ultima_actualizacion": "2025-10-26 18:40:23"
  }
}
```

### 2. Actualizar Configuración
```
POST http://localhost:8000/admin/update_pricing_config.php
Content-Type: application/json

{
  "id": 1,
  "tarifa_base": 4500.00,
  "costo_por_km": 300.00,
  "costo_por_minuto": 2500.00,
  "tarifa_minima": 6500.00,
  "recargo_hora_pico": 20.00,
  "recargo_nocturno": 25.00,
  "recargo_festivo": 30.00,
  "comision_plataforma": 15.00
}
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "message": "Configuración de precios actualizada exitosamente",
  "data": { ... }
}
```

## 🧪 Pruebas

### Método 1: Probar Conexión Primero (RECOMENDADO)
```bash
# 1. Verificar conexión a la base de datos
cd C:\Flutter\ping_go
php test_connection.php

# 2. Si todo está bien, iniciar servidor
powershell -ExecutionPolicy Bypass -File start_server.ps1

# 3. En otra terminal, probar endpoints
php test_pricing_endpoints.php
```

### Método 2: Script PowerShell Automatizado
```powershell
cd C:\Flutter\ping_go
.\test_pricing_api.ps1
```

### Método 3: Manual
```bash
# Terminal 1: Iniciar servidor
cd C:\Flutter\ping_go\pingo\backend
php -S localhost:8000

# Terminal 2: Ejecutar pruebas
cd C:\Flutter\ping_go
php test_pricing_endpoints.php
```

### Método 4: Desde Flutter
```bash
# Asegúrate que el servidor PHP esté corriendo
php test_connection.php  # Primero verifica la conexión
powershell -ExecutionPolicy Bypass -File start_server.ps1  # Inicia el servidor
flutter run  # Ejecuta la app
# Luego navega: Login (admin) → Gestión → Tarifas y Comisiones
```

## 📂 Archivos Creados

### Frontend (Flutter)
```
lib/src/features/admin/presentation/screens/
  └─ pricing_management_screen.dart  (586 líneas)

lib/src/routes/
  ├─ route_names.dart               (actualizado)
  └─ app_router.dart                (actualizado)
```

### Backend (PHP)
```
pingo/backend/admin/
  ├─ get_pricing_configs.php        (Obtener configuraciones)
  └─ update_pricing_config.php      (Actualizar configuración)
```

### Scripts de Prueba
```
start_server.ps1                    (Iniciar servidor PHP)
test_connection.php                 (Verificar conexión DB)
test_pricing_api.ps1                (Script PowerShell automatizado)
test_pricing_endpoints.php          (Pruebas de endpoints)
README_PRICING_MANAGEMENT.md       (Esta documentación)
```

## 🎨 Diseño UI

- **Tema**: Dark mode con glassmorphism
- **Colores por vehículo**:
  - Moto: Amarillo (#FFFF00)
  - Carro: Púrpura (#667eea)
  - Moto Carga: Verde (#11998e)
  - Carro Carga: Naranja (#ffa726)
- **Animaciones**: Transiciones suaves en diálogos
- **Validación**: En tiempo real con TextField formatters

## 🔒 Seguridad

- ✅ Validación de datos en backend
- ✅ Sanitización de inputs
- ✅ Prepared statements (PDO)
- ✅ Logs de auditoría automáticos
- ✅ Validación de rangos (porcentajes 0-100, valores positivos)

## 📊 Logs de Auditoría

Cada cambio se registra automáticamente en `logs_auditoria`:

```sql
SELECT * FROM logs_auditoria 
WHERE accion = 'update' AND tabla_afectada = 'configuracion_precios'
ORDER BY fecha_hora DESC;
```

## 🚀 Próximas Mejoras

- [ ] Historial visual de cambios por configuración
- [ ] Comparador de precios entre tipos de vehículo
- [ ] Calculadora de precios en tiempo real
- [ ] Exportar configuraciones a JSON/CSV
- [ ] Duplicar configuración para crear nuevas
- [ ] Activar/desactivar configuraciones con toggle

## 📝 Notas Importantes

1. Solo administradores pueden acceder a esta funcionalidad
2. Los cambios se aplican inmediatamente en el sistema
3. Se recomienda hacer cambios en horarios de baja demanda
4. Siempre verificar los valores antes de guardar

## 🐛 Troubleshooting

### Error: "ClientException: Connection closed while receiving data"
```bash
# 1. Verificar conexión a base de datos
php test_connection.php

# 2. Verificar que el servidor NO esté corriendo
netstat -ano | findstr :8000

# 3. Si está corriendo, detenerlo (buscar PID y matar proceso)
# Si no está corriendo, iniciarlo:
powershell -ExecutionPolicy Bypass -File start_server.ps1
```

### Error: "No se puede conectar al servidor"
```bash
# Verificar que el servidor PHP esté corriendo
netstat -ano | findstr :8000

# Si no está corriendo, iniciarlo
cd C:\Flutter\ping_go
powershell -ExecutionPolicy Bypass -File start_server.ps1
```

### Error: "Configuración no encontrada"
```sql
-- Verificar que existan configuraciones activas
SELECT * FROM configuracion_precios WHERE activo = 1;

-- Si no hay, ejecutar la migración
php pingo/backend/migrations/run_migration_007.php
```

### Error de validación en Flutter
- Verificar que los valores sean numéricos
- Porcentajes deben estar entre 0 y 100
- Valores monetarios deben ser positivos

### Error: "Access denied for user"
```bash
# Verificar credenciales en config/database.php
# Por defecto debe ser:
# Usuario: root
# Contraseña: (vacía)
# Base de datos: pingo
```

## 👨‍💻 Desarrollo

**Autor**: GitHub Copilot  
**Fecha**: Octubre 2025  
**Versión**: 1.0.0  
**Stack**: Flutter + PHP + MySQL

---

Para soporte o reportar bugs, contacta al administrador del sistema.
