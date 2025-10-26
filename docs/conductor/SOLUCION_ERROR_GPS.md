# Solución al Error de Ubicación GPS

## 🔧 Problema
La app muestra: "Error obteniendo ubicación" cuando el conductor activa el modo de búsqueda.

## ✅ Soluciones

### Opción 1: Configurar GPS en el Emulador (Recomendado)

1. **Abrir Extended Controls**
   - En el emulador, haz clic en los tres puntos `⋮` (esquina derecha)
   - O presiona `Ctrl + Shift + P`

2. **Ir a Location**
   - En el menú lateral, selecciona `Location`

3. **Establecer Ubicación**
   - **Latitude**: `4.6097`
   - **Longitude**: `-74.0817`
   - Haz clic en `SEND`

4. **Activar GPS Mock**
   - En el emulador, ve a `Settings > Developer Options`
   - Busca `Select mock location app`
   - Selecciona `ping_go`

### Opción 2: Usar Ubicación por Defecto (Automático)

La app ahora está configurada para usar una ubicación por defecto (Bogotá) si el GPS falla:
- **Latitude**: 4.6097
- **Longitude**: -74.0817

Esto permite que la app funcione incluso sin GPS real.

### Opción 3: Dispositivo Físico

Si usas un dispositivo físico:

1. **Activar GPS**
   - Ve a `Configuración > Ubicación`
   - Activa la ubicación

2. **Permisos de App**
   - Ve a `Configuración > Apps > ping_go > Permisos`
   - Habilita `Ubicación` como `Permitir siempre`

3. **Cambiar IP en el Código**
   - En `app_config.dart`, cambia `10.0.2.2` por tu IP local
   - Encuentra tu IP con: `ipconfig` (Windows)
   - Ejemplo: `192.168.18.68`

## 🧪 Verificar que Funciona

1. Hot restart de la app: `r`
2. Inicia sesión como conductor
3. Activa el toggle
4. Deberías ver:
   - ✅ Mapa centrado en tu ubicación (o Bogotá por defecto)
   - ✅ Panel superior: "Estás disponible"
   - ✅ Búsqueda automática de solicitudes

## 📝 Logs Útiles

La app ahora muestra logs detallados:
```
📍 Iniciando tracking de ubicación...
📍 Permiso actual: whileInUse
✅ Ubicación obtenida: 4.6097, -74.0817
🔍 Iniciando búsqueda de solicitudes...
✅ Solicitudes encontradas: 1
```

Si ves estos logs en la consola, todo está funcionando correctamente.

## ⚠️ Notas

- El emulador puede tardar 5-10 segundos en obtener ubicación GPS
- La app usa ubicación de prueba (Bogotá) si el GPS falla
- Esto permite desarrollar y probar sin depender del GPS real
