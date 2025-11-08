import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Servicio para manejar la reproducciÃ³n de sonidos en la aplicaciÃ³n
///
/// Especialmente para notificaciones de nuevas solicitudes de viaje
class SoundService {
  // Usar un player dedicado para solicitudes
  static final AudioPlayer _requestPlayer = AudioPlayer();
  static final AudioPlayer _acceptPlayer = AudioPlayer();
  static bool _hasError = false;
  static bool _isPlayingRequestLoop = false;

  /// Reproduce el sonido de notificaciÃ³n de nueva solicitud en loop continuo
  /// Similar a la notificaciÃ³n de Uber/DiDi cuando llega un viaje
  /// Se repite hasta que se acepte o rechace la solicitud
  static Future<void> playRequestNotification() async {
    print('ðŸ”Š [DEBUG] ==========================================');
    print('ðŸ”Š [DEBUG] Iniciando loop continuo de sonido de solicitud...');

    // Si ya estÃ¡ reproduciendo, no hacer nada
    if (_isPlayingRequestLoop) {
      print('ðŸ”Š [DEBUG] Loop ya estÃ¡ activo, omitiendo...');
      return;
    }

    // Primero intentar vibraciÃ³n como feedback inmediato
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      print('ðŸ“³ [DEBUG] âœ… VibraciÃ³n ejecutada como feedback');
    } catch (e) {
      print('âŒ [ERROR] Error al vibrar: $e');
    }

    if (_hasError) {
      print('âš ï¸ [WARN] AudioPlayer no disponible, usando solo vibraciÃ³n');
      return;
    }

    try {
      // Detener cualquier reproducciÃ³n anterior
      await _requestPlayer.stop();
      print('ðŸ”Š [DEBUG] Player detenido');

      // Configurar el contexto de audio para notificaciÃ³n
      await _requestPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      print('ðŸ”Š [DEBUG] Contexto de audio configurado para Android');

      // Configurar volumen al mÃ¡ximo
      await _requestPlayer.setVolume(1.0);
      print('ðŸ”Š [DEBUG] Volumen configurado a 1.0');

      // Configurar modo de liberaciÃ³n para loop continuo
      await _requestPlayer.setReleaseMode(ReleaseMode.loop);
      print('ðŸ”Š [DEBUG] Release mode configurado para loop continuo');

      // Configurar source con playerMode LOW_LATENCY para mejor reproducciÃ³n
      await _requestPlayer.setPlayerMode(PlayerMode.lowLatency);
      print('ðŸ”Š [DEBUG] Player mode LOW_LATENCY configurado');

      // Intentar reproducir el archivo WAV en loop continuo
      print('ðŸ”Š [DEBUG] Reproduciendo en loop: assets/sounds/request_notification.wav');

      final source = AssetSource('sounds/request_notification.wav');

      // Marcar que estamos reproduciendo el loop
      _isPlayingRequestLoop = true;

      // Escuchar eventos del player
      _requestPlayer.onPlayerComplete.listen((event) {
        print('ðŸ”Š [DEBUG] âœ… Sonido completado (loop continuo)');
      });

      _requestPlayer.onPlayerStateChanged.listen((state) {
        print('ðŸ”Š [DEBUG] Estado del player: $state');
      });

      // Iniciar reproducciÃ³n en loop
      await _requestPlayer.play(source);
      print('ðŸ”Š [DEBUG] âœ… Â¡Loop continuo iniciado!');

      print('ðŸ”Š [DEBUG] ==========================================');

    } catch (e, stackTrace) {
      print('âŒ [ERROR] Error al iniciar loop de sonido: $e');
      print('âŒ [STACK] $stackTrace');
      print('ðŸ”Š [DEBUG] ==========================================');

      // Marcar como error para no intentar mÃ¡s
      _hasError = true;
      _isPlayingRequestLoop = false;
    }
  }

  /// Reproduce un sonido de confirmaciÃ³n al aceptar un viaje
  static Future<void> playAcceptSound() async {
    // VibraciÃ³n como feedback inmediato
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('âŒ Error al vibrar: $e');
    }

    if (_hasError) {
      return;
    }

    try {
      await _acceptPlayer.stop();
      await _acceptPlayer.setVolume(0.7);
      await _acceptPlayer.setReleaseMode(ReleaseMode.stop);

      // Usar un tono simple
      await _acceptPlayer.play(
        AssetSource('sounds/beep.wav'),
      );

      print('ðŸ”Š Sonido de aceptaciÃ³n reproducido');
    } catch (e) {
      print('âŒ Error al reproducir sonido de aceptaciÃ³n: $e');
    }
  }

  /// Detiene cualquier sonido que se estÃ© reproduciendo
  static Future<void> stopSound() async {
    try {
      await _requestPlayer.stop();
      await _acceptPlayer.stop();
      _isPlayingRequestLoop = false; // Resetear el flag del loop
      print('ðŸ”Š [DEBUG] Sonidos detenidos y loop reseteado');
    } catch (e) {
      print('âŒ Error al detener sonido: $e');
    }
  }

  /// Libera los recursos del reproductor de audio
  static Future<void> dispose() async {
    try {
      await _requestPlayer.dispose();
      await _acceptPlayer.dispose();
      _hasError = false;
    } catch (e) {
      print('âŒ Error al liberar reproductor de audio: $e');
    }
  }
}
