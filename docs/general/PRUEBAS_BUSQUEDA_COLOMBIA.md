# 🔍 Guía de Pruebas - Sistema de Búsqueda en Colombia

## Resumen
El sistema de búsqueda ahora está completamente optimizado para Colombia usando Nominatim API. Esta guía te ayudará a probar el sistema correctamente.

## ✅ Configuración Actual

### API Utilizada
- **Servicio:** Nominatim (OpenStreetMap)
- **Costo:** 100% GRATIS
- **País:** Colombia (código: `co`)
- **Idioma:** Español prioritario
- **Límite:** 10 resultados por búsqueda

### Características Activadas
- ✅ Filtrado automático por Colombia
- ✅ Priorización por proximidad geográfica
- ✅ Debounce de 500ms para evitar spam
- ✅ Búsqueda con mínimo 3 caracteres
- ✅ Autocompletado inteligente

## 🧪 Casos de Prueba

### Santander - San Gil

#### Lugares Turísticos
```
✅ "Parque El Gallineral"
✅ "Catedral de San Gil"
✅ "Parque Principal San Gil"
✅ "Malecón San Gil"
✅ "Balneario Pozo Azul"
```

#### Direcciones Comunes
```
✅ "Carrera 10 San Gil"
✅ "Calle 12 San Gil"
✅ "Calle 10 con Carrera 9"
✅ "Centro San Gil"
```

#### Servicios
```
✅ "Hospital San Gil"
✅ "Terminal de Transportes San Gil"
✅ "Alcaldía San Gil"
✅ "Policía San Gil"
```

### Medellín (Para Pruebas)

#### Colegios
```
✅ "Colegio La Primavera Medellín"
✅ "Colegio San José de Las Vegas"
✅ "Institución Educativa San Antonio de Prado"
```

#### Lugares Famosos
```
✅ "Parque Arví"
✅ "Plaza Botero"
✅ "Pueblito Paisa"
✅ "Jardín Botánico Medellín"
✅ "Metro Cable Medellín"
```

#### Barrios
```
✅ "El Poblado"
✅ "Laureles"
✅ "Envigado"
✅ "Sabaneta"
```

### Bogotá

#### Lugares Icónicos
```
✅ "Parque Simón Bolívar"
✅ "Monserrate"
✅ "Zona T"
✅ "Usaquén"
✅ "Centro Internacional"
```

#### Universidades
```
✅ "Universidad Nacional Bogotá"
✅ "Universidad de Los Andes"
✅ "Javeriana"
```

## 🎯 Cómo Probar

### 1. Búsqueda en RequestTripScreen
1. Abre la app
2. Navega a solicitar viaje
3. Toca el campo de origen o destino
4. Escribe alguno de los casos de prueba
5. Verifica que aparezcan resultados

### 2. Búsqueda en AddressStepWidget (Registro)
1. Abre el proceso de registro
2. Llega al paso de dirección
3. Usa la barra de búsqueda superior
4. Escribe alguno de los casos de prueba
5. Verifica que aparezcan resultados

### 3. Verificar Proximidad
1. Permite acceso a ubicación
2. Busca un lugar genérico (ej: "Hospital")
3. Verifica que los resultados estén ordenados por cercanía
4. Los más cercanos deben aparecer primero

## 🐛 Problemas Comunes y Soluciones

### No Aparecen Resultados

**Problema:** Al buscar "Colegio La Primavera Medellín" no aparece nada

**Posibles Causas:**
1. ❌ Búsqueda con menos de 3 caracteres
2. ❌ No está en OpenStreetMap
3. ❌ Nombre no coincide exactamente

**Soluciones:**
```dart
// ✅ Probar variaciones del nombre
"La Primavera"
"Colegio Primavera"
"Institución La Primavera"

// ✅ Buscar solo por zona
"La Primavera Medellín"
"Primavera Poblado"

// ✅ Buscar por dirección cercana
"Carrera 43A Medellín"
```

### Resultados Fuera de Colombia

**Problema:** Aparecen resultados de otros países

**Causa:** El parámetro `countrycodes=co` no está aplicándose

**Solución:**
```dart
// Verificar en nominatim_service.dart línea ~20
'countrycodes': 'co', // ✅ Debe estar presente
```

### Búsqueda Muy Lenta

**Problema:** La búsqueda tarda mucho

**Causas:**
1. Conexión lenta
2. Timeout muy largo

**Solución:**
```dart
// Ajustar timeout en nominatim_service.dart
.timeout(const Duration(seconds: 10)); // Reducir si es necesario
```

### No Prioriza Resultados Cercanos

**Problema:** Los resultados no están ordenados por proximidad

**Causa:** No se está pasando el parámetro `proximity`

**Solución:**
```dart
// En map_provider.dart debe tener:
_searchResults = await NominatimService.searchAddress(
  query,
  proximity: _currentLocation ?? _selectedLocation, // ✅ Importante
  limit: 10,
);
```

## 📊 Logs de Debugging

### Activar Logs Detallados

Los logs ya están activados por defecto:

```dart
// En nominatim_service.dart verás:
🔍 Buscando en Nominatim: ...
✅ Encontrados X lugares en Colombia
📍 Geocodificación inversa: lat, lon
❌ Error en la búsqueda: ...
```

### Verificar en Consola

```powershell
# Al ejecutar la app, verás en la consola:
flutter run
# Outputs:
# 🔍 Buscando en Nominatim: .../search?format=json&q=Colegio+La+Primavera...
# ✅ Encontrados 5 lugares en Colombia
```

## 🔧 Debugging Manual

### Probar API Directamente

Puedes probar la API de Nominatim en el navegador:

```
https://nominatim.openstreetmap.org/search?format=json&q=Colegio+La+Primavera+Medellín&countrycodes=co&addressdetails=1&limit=10&accept-language=es
```

Si la API devuelve resultados pero tu app no, el problema está en el código.

## 📝 Checklist de Verificación

Antes de reportar un problema, verifica:

- [ ] La búsqueda tiene al menos 3 caracteres
- [ ] El debounce de 500ms está activo
- [ ] La ubicación del dispositivo está habilitada
- [ ] El parámetro `countrycodes=co` está en la petición
- [ ] Los logs muestran la búsqueda en Nominatim
- [ ] La API devuelve resultados (probar en navegador)
- [ ] El provider tiene la ubicación actual (`currentLocation`)

## 🎓 Ejemplos de Búsquedas Exitosas

### Formato Recomendado

```
✅ [Nombre del Lugar] + [Ciudad]
   Ejemplo: "Colegio La Primavera Medellín"

✅ [Nombre Genérico] + [Zona]
   Ejemplo: "Hospital El Poblado"

✅ [Dirección] + [Ciudad]
   Ejemplo: "Carrera 10 San Gil"

✅ Solo [Nombre Famoso]
   Ejemplo: "Parque El Gallineral"
```

### Formato NO Recomendado

```
❌ Muy genérico sin contexto
   Ejemplo: "Hospital"

❌ Abreviaciones no estándar
   Ejemplo: "Col. Prim."

❌ Con errores ortográficos
   Ejemplo: "Colegio Primabera"
```

## 🚀 Optimizaciones Futuras

1. **Caché de Búsquedas**
   - Guardar búsquedas recientes localmente
   - Reducir llamadas a la API

2. **Sugerencias Inteligentes**
   - Autocompletar basado en historial
   - Sugerencias populares por zona

3. **Búsqueda Fuzzy Mejorada**
   - Corrección automática de ortografía
   - Sinónimos y variaciones

4. **Filtros Adicionales**
   - Por tipo de lugar (colegio, hospital, etc.)
   - Por departamento específico

## 📞 Soporte

Si encuentras un lugar que NO aparece en la búsqueda:

1. Verifica que exista en [OpenStreetMap](https://www.openstreetmap.org/)
2. Si no existe, puedes agregarlo tú mismo (es colaborativo)
3. Prueba variaciones del nombre
4. Busca por dirección cercana

---

**Última Actualización:** 26 de Octubre, 2025
**Versión:** 2.0 - Sistema Nominatim Optimizado para Colombia
