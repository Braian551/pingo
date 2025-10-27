# 🔊 Instrucciones para agregar sonidos de notificación

## Archivos de sonido necesarios

Debes agregar los siguientes archivos de audio a esta carpeta:

### 1. `request_notification.mp3` (REQUERIDO)
- **Propósito**: Sonido que se reproduce cuando llega una nueva solicitud de viaje
- **Duración recomendada**: 2-5 segundos
- **Estilo**: Similar a las notificaciones de Uber/DiDi/Cabify
- **Volumen**: Fuerte y claro para llamar la atención del conductor

### 2. `accept.mp3` (OPCIONAL)
- **Propósito**: Sonido de confirmación al aceptar un viaje
- **Duración recomendada**: 1-2 segundos
- **Estilo**: Sonido positivo y de confirmación

## ¿Dónde conseguir los sonidos?

### Opción 1: Sitios de sonidos gratuitos
- [Freesound.org](https://freesound.org/) - Busca "notification sound", "alert", "ping"
- [Zapsplat.com](https://www.zapsplat.com/) - Categoría "UI Sounds"
- [Mixkit.co](https://mixkit.co/free-sound-effects/) - Sonidos UI gratuitos

### Opción 2: Crear tu propio sonido
Puedes usar apps como:
- **Audacity** (gratis) - Editor de audio
- **GarageBand** (Mac/iOS) - Crear tonos personalizados
- **FL Studio Mobile** (Android/iOS) - Crear beats y tonos

### Opción 3: Usar sonidos de sistema
Puedes grabar o extraer sonidos de:
- Notificaciones de tu teléfono
- Apps similares (Uber, DiDi, etc.) - Solo para uso personal
- Tonos de alerta del sistema

## Formatos soportados

La librería `audioplayers` soporta:
- ✅ MP3 (recomendado)
- ✅ WAV
- ✅ OGG
- ✅ AAC

## Ejemplo de búsqueda en Freesound

1. Ve a https://freesound.org/
2. Busca: "notification alert" o "ping sound"
3. Filtra por:
   - Duración: 0-5 segundos
   - Licencia: Creative Commons 0 (dominio público)
4. Descarga y renombra como `request_notification.mp3`
5. Coloca el archivo en esta carpeta

## Recomendaciones

- **Volumen**: No debe ser muy fuerte para no asustar al conductor
- **Duración**: Corto pero distintivo (2-3 segundos ideal)
- **Tono**: Urgente pero no agresivo
- **Prueba**: Prueba el sonido mientras conduces para verificar que sea audible

## ⚠️ IMPORTANTE

Si no agregas el archivo `request_notification.mp3`, la app seguirá funcionando pero no reproducirá sonido. Revisa la consola para ver el error:
```
❌ Error al reproducir sonido: ...
```

## Sonido temporal para pruebas

Si quieres probar rápidamente sin buscar un sonido profesional:

1. Graba 2-3 segundos de tu voz diciendo "Nueva solicitud"
2. Convierte a MP3 (usa https://online-audio-converter.com/)
3. Guarda como `request_notification.mp3` en esta carpeta

¡Ya está listo para usar! 🎉
