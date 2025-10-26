# Sistema de Dos Pantallas para Solicitud de Viajes (Estilo DiDi)

## 📋 Resumen

Se ha implementado un sistema de solicitud de viajes en dos etapas, similar a DiDi y otras apps de transporte modernas:

1. **Pantalla 1:** Selección de origen, destino y tipo de vehículo
2. **Pantalla 2:** Visualización del mapa con ruta trazada, cotización detallada y confirmación

## 🗂️ Archivos Creados

### **Base de Datos**
- `pingo/backend/migrations/007_create_configuracion_precios.sql`
  - Tabla `configuracion_precios`: Configuración de tarifas por tipo de vehículo
  - Tabla `historial_precios`: Auditoría de cambios de precios
  - Vista `vista_precios_activos`: Consulta rápida de precios con período actual
  - 4 configuraciones por defecto (moto, carro, moto_carga, carro_carga)

### **Backend PHP**
- `pingo/backend/pricing/get_config.php`
  - Obtiene configuración de precios para un tipo de vehículo
  - Calcula período actual (normal, hora pico, nocturno)
  - **Endpoint:** `GET /pricing/get_config.php?tipo_vehiculo=moto`

- `pingo/backend/pricing/calculate_quote.php`
  - Calcula cotización completa del viaje
  - Aplica tarifas, descuentos y recargos
  - **Endpoint:** `POST /pricing/calculate_quote.php`
  ```json
  {
    "distancia_km": 8.5,
    "duracion_minutos": 25,
    "tipo_vehiculo": "moto"
  }
  ```

### **Flutter - Pantallas**
- `lib/src/features/user/presentation/screens/select_destination_screen.dart`
  - Primera pantalla: Selección de origen y destino
  - Búsqueda de lugares con Mapbox
  - Selección de tipo de vehículo (moto, carro, moto/carro carga)
  - UI limpia y moderna sin mapa
  
- `lib/src/features/user/presentation/screens/trip_preview_screen.dart`
  - Segunda pantalla: Preview del viaje
  - Mapa con ruta trazada
  - Marcadores de origen y destino
  - Panel inferior con cotización detallada
  - Desglose de precios expandible
  - Botón de confirmación

## 📊 Tabla de Configuración de Precios

### Estructura de `configuracion_precios`

| Campo | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| `tipo_vehiculo` | ENUM | moto, carro, moto_carga, carro_carga | 'moto' |
| `tarifa_base` | DECIMAL | Tarifa mínima por viaje | 4000.00 |
| `costo_por_km` | DECIMAL | Precio por kilómetro | 2000.00 |
| `costo_por_minuto` | DECIMAL | Precio por minuto | 250.00 |
| `tarifa_minima` | DECIMAL | Precio mínimo total | 6000.00 |
| `recargo_hora_pico` | DECIMAL | Porcentaje de recargo (7-9am, 5-7pm) | 15.00 |
| `recargo_nocturno` | DECIMAL | Porcentaje de recargo (10pm-6am) | 20.00 |
| `recargo_festivo` | DECIMAL | Porcentaje de recargo días festivos | 25.00 |
| `comision_plataforma` | DECIMAL | Porcentaje para la plataforma | 15.00 |

### Valores por Defecto

#### 🏍️ Moto
- Tarifa base: $4,000
- Por km: $2,000
- Por minuto: $250
- Mínimo: $6,000

#### 🚗 Carro
- Tarifa base: $6,000
- Por km: $3,000
- Por minuto: $400
- Mínimo: $9,000

#### 🏍️📦 Moto Carga
- Tarifa base: $5,000
- Por km: $2,500
- Por minuto: $300
- Mínimo: $7,500

#### 🚚 Carro Carga
- Tarifa base: $8,000
- Por km: $3,500
- Por minuto: $450
- Mínimo: $12,000

## 🔧 Instalación

### 1. Ejecutar Migración de Base de Datos

```bash
# Opción 1: Desde MySQL Workbench
# - Abrir el archivo 007_create_configuracion_precios.sql
# - Ejecutar todo el script

# Opción 2: Desde línea de comandos
mysql -u root -p pingo < pingo/backend/migrations/007_create_configuracion_precios.sql
```

### 2. Verificar la Instalación

```sql
-- Verificar que las tablas se crearon
SHOW TABLES LIKE '%precio%';

-- Ver configuraciones por defecto
SELECT tipo_vehiculo, tarifa_base, costo_por_km, tarifa_minima 
FROM configuracion_precios 
WHERE activo = 1;

-- Ver la vista de precios activos
SELECT * FROM vista_precios_activos;
```

### 3. Probar los Endpoints

```bash
# Obtener configuración de moto
curl "http://localhost/pingo/backend/pricing/get_config.php?tipo_vehiculo=moto"

# Calcular cotización
curl -X POST http://localhost/pingo/backend/pricing/calculate_quote.php \
  -H "Content-Type: application/json" \
  -d '{
    "distancia_km": 8.5,
    "duracion_minutos": 25,
    "tipo_vehiculo": "moto"
  }'
```

## 🎯 Fórmula de Cálculo de Precios

```
Subtotal = Tarifa Base + (Distancia × Costo/km) + (Duración × Costo/min)

Descuento = Si distancia ≥ 15km → Subtotal × 10%

Recargo = Subtotal × (Porcentaje según período)
  - Hora pico (7-9am, 5-7pm): +15-20%
  - Nocturno (10pm-6am): +20-25%
  - Festivo: +25-30%

Total = Subtotal - Descuento + Recargo
Total = MAX(Total, Tarifa Mínima)
```

## 🎨 Flujo de Usuario

```
1. Usuario abre la app
   ↓
2. Selecciona "Solicitar viaje"
   ↓
3. Pantalla 1: SelectDestinationScreen
   - Busca y selecciona origen
   - Busca y selecciona destino
   - Elige tipo de vehículo (moto, carro, etc.)
   - Presiona "Ver Cotización"
   ↓
4. Pantalla 2: TripPreviewScreen
   - Ve el mapa con la ruta trazada
   - Ve distancia y tiempo estimado
   - Ve precio calculado
   - Puede expandir desglose de precio
   - Presiona "Solicitar viaje"
   ↓
5. Se crea la solicitud (TODO: implementar)
```

## 👨‍💼 Panel de Administración

### Modificar Precios

Los administradores pueden modificar los precios directamente en la base de datos:

```sql
-- Actualizar precio por km de motos
UPDATE configuracion_precios 
SET costo_por_km = 2200.00,
    notas = 'Ajuste por inflación - Octubre 2025'
WHERE tipo_vehiculo = 'moto';

-- Cambiar recargo nocturno
UPDATE configuracion_precios 
SET recargo_nocturno = 25.00 
WHERE tipo_vehiculo = 'carro';
```

**Nota:** Todos los cambios se registran automáticamente en `historial_precios` mediante triggers (TODO: implementar triggers).

## 🔮 Próximos Pasos

### Inmediato
- [ ] Conectar `TripPreviewScreen` con el endpoint `calculate_quote.php`
- [ ] Reemplazar cálculo local por llamada al backend
- [ ] Implementar confirmación de viaje real

### Corto Plazo
- [ ] Panel admin para modificar precios desde la app
- [ ] Tabla de días festivos
- [ ] Sistema de promociones y descuentos
- [ ] Triggers para auditoría automática

### Mediano Plazo
- [ ] Precios dinámicos según demanda
- [ ] Zonas con tarifas diferentes
- [ ] Paquetes y membresías
- [ ] Sistema de cupones

## 📝 Ejemplo de Respuesta de Cotización

```json
{
  "success": true,
  "data": {
    "distancia_km": 8.5,
    "duracion_minutos": 25,
    "tipo_vehiculo": "moto",
    "tarifa_base": 4000,
    "precio_distancia": 17000,
    "precio_tiempo": 6250,
    "subtotal": 27250,
    "descuento_distancia": 0,
    "recargo_porcentaje": 15,
    "recargo_precio": 4087.5,
    "total": 31337.5,
    "total_formateado": "$31.338",
    "periodo_actual": "hora_pico",
    "comision_plataforma": 4700.63,
    "ganancia_conductor": 26636.87
  }
}
```

## 🐛 Debug y Testing

### Verificar Período Actual

```sql
SELECT tipo_vehiculo, periodo_actual, recargo_actual 
FROM vista_precios_activos;
```

### Simular Diferentes Horarios

```sql
-- Cambiar horarios de hora pico para testing
UPDATE configuracion_precios 
SET hora_pico_inicio_manana = '14:00:00',
    hora_pico_fin_manana = '16:00:00'
WHERE tipo_vehiculo = 'moto';
```

## 📞 Soporte

Para modificaciones o dudas sobre el sistema de precios:
1. Revisar este README
2. Consultar `007_create_configuracion_precios.sql` para estructura completa
3. Ver ejemplos en `calculate_quote.php`

---

**Versión:** 1.0.0  
**Fecha:** Octubre 2025  
**Última actualización:** 26 de Octubre de 2025
