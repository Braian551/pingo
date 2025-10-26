# 🚀 Inicio Rápido - Sistema de Dos Pantallas

## Para el Administrador / Desarrollador

### 1. Instalar Base de Datos (5 minutos)

```bash
# Abrir terminal en la carpeta de migraciones
cd c:\Flutter\ping_go\pingo\backend\migrations

# Ejecutar el script de instalación
install_precios.bat

# O manualmente con MySQL:
mysql -u root -p pingo < 007_create_configuracion_precios.sql
```

### 2. Verificar que Funcionó

```bash
# Probar endpoint de configuración
curl http://localhost/pingo/backend/pricing/get_config.php?tipo_vehiculo=moto

# Probar endpoint de cotización
curl -X POST http://localhost/pingo/backend/pricing/calculate_quote.php ^
  -H "Content-Type: application/json" ^
  -d "{\"distancia_km\":8.5,\"duracion_minutos\":25,\"tipo_vehiculo\":\"moto\"}"
```

Si ves JSON con datos de precios = ✅ Funciona!

### 3. Probar en la App

```bash
# Ejecutar app Flutter
cd c:\Flutter\ping_go
flutter run
```

1. Login como usuario
2. Clic en "Solicitar viaje"
3. Seleccionar origen y destino
4. Elegir tipo de vehículo
5. Ver cotización con mapa

---

## Para Modificar Precios

```sql
-- Conectar a MySQL
mysql -u root -p pingo

-- Ver precios actuales
SELECT tipo_vehiculo, tarifa_base, costo_por_km, tarifa_minima 
FROM configuracion_precios;

-- Cambiar precio de motos
UPDATE configuracion_precios 
SET costo_por_km = 2200.00 
WHERE tipo_vehiculo = 'moto';

-- Cambiar recargo nocturno
UPDATE configuracion_precios 
SET recargo_nocturno = 22.00 
WHERE tipo_vehiculo = 'carro';
```

---

## Archivos Importantes

- 📄 `docs/IMPLEMENTACION_COMPLETADA_SISTEMA_PRECIOS.md` - Documentación completa
- 📄 `docs/SISTEMA_PRECIOS_DOBLE_PANTALLA.md` - Guía técnica detallada
- 🗄️ `pingo/backend/migrations/007_create_configuracion_precios.sql` - Script de base de datos
- 🌐 `pingo/backend/pricing/` - APIs de precios
- 📱 `lib/src/features/user/presentation/screens/select_destination_screen.dart` - Pantalla 1
- 📱 `lib/src/features/user/presentation/screens/trip_preview_screen.dart` - Pantalla 2

---

## Solución de Problemas

### Error: "Tabla no encontrada"
```bash
# Verificar que la migración se ejecutó
mysql -u root -p pingo -e "SHOW TABLES LIKE '%precio%';"

# Re-ejecutar si es necesario
mysql -u root -p pingo < pingo/backend/migrations/007_create_configuracion_precios.sql
```

### Error: "No se puede conectar a la base de datos"
- Verificar que XAMPP/MySQL está corriendo
- Verificar credenciales en `pingo/backend/config/database.php`

### Error en Flutter: "No route defined"
```bash
# Asegurar que los imports están correctos
flutter clean
flutter pub get
flutter run
```

---

## Precios por Defecto

| Vehículo | Tarifa Base | Por KM | Por Min | Mínimo |
|----------|-------------|--------|---------|---------|
| Moto | $4,000 | $2,000 | $250 | $6,000 |
| Carro | $6,000 | $3,000 | $400 | $9,000 |
| Moto Carga | $5,000 | $2,500 | $300 | $7,500 |
| Carro Carga | $8,000 | $3,500 | $450 | $12,000 |

**Recargos:**
- Hora pico (7-9am, 5-7pm): +15-20%
- Nocturno (10pm-6am): +20-25%
- Festivo: +25-30%

**Descuentos:**
- Distancia >15km: -10%

---

**¿Necesitas más ayuda?** Lee `IMPLEMENTACION_COMPLETADA_SISTEMA_PRECIOS.md`
