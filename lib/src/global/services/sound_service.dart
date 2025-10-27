import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Servicio para manejar la reproducción de sonidos en la aplicación
///
/// Especialmente para notificaciones de nuevas solicitudes de viaje
class SoundService {
  // Usar un player dedicado para solicitudes
  static final AudioPlayer _requestPlayer = AudioPlayer();
  static final AudioPlayer _acceptPlayer = AudioPlayer();
  static bool _hasError = false;
  static bool _isPlayingRequestLoop = false;

  /// Reproduce el sonido de notificación de nueva solicitud en loop continuo
  /// Similar a la notificación de Uber/DiDi cuando llega un viaje
  /// Se repite hasta que se acepte o rechace la solicitud
  static Future<void> playRequestNotification() async {
    print('🔊 [DEBUG] ==========================================');
    print('🔊 [DEBUG] Iniciando loop continuo de sonido de solicitud...');

    // Si ya está reproduciendo, no hacer nada
    if (_isPlayingRequestLoop) {
      print('🔊 [DEBUG] Loop ya está activo, omitiendo...');
      return;
    }

    // Primero intentar vibración como feedback inmediato
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      print('📳 [DEBUG] ✅ Vibración ejecutada como feedback');
    } catch (e) {
      print('❌ [ERROR] Error al vibrar: $e');
    }

    if (_hasError) {
      print('⚠️ [WARN] AudioPlayer no disponible, usando solo vibración');
      return;
    }

    try {
      // Detener cualquier reproducción anterior
      await _requestPlayer.stop();
      print('🔊 [DEBUG] Player detenido');

      // Configurar el contexto de audio para notificación
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
      print('🔊 [DEBUG] Contexto de audio configurado para Android');

      // Configurar volumen al máximo
      await _requestPlayer.setVolume(1.0);
      print('🔊 [DEBUG] Volumen configurado a 1.0');

      // Configurar modo de liberación para loop continuo
      await _requestPlayer.setReleaseMode(ReleaseMode.loop);
      print('🔊 [DEBUG] Release mode configurado para loop continuo');

      // Configurar source con playerMode LOW_LATENCY para mejor reproducción
      await _requestPlayer.setPlayerMode(PlayerMode.lowLatency);
      print('🔊 [DEBUG] Player mode LOW_LATENCY configurado');

      // Intentar reproducir el archivo WAV en loop continuo
      print('🔊 [DEBUG] Reproduciendo en loop: assets/sounds/request_notification.wav');

      final source = AssetSource('sounds/request_notification.wav');

      // Marcar que estamos reproduciendo el loop
      _isPlayingRequestLoop = true;

      // Escuchar eventos del player
      _requestPlayer.onPlayerComplete.listen((event) {
        print('🔊 [DEBUG] ✅ Sonido completado (loop continuo)');
      });

      _requestPlayer.onPlayerStateChanged.listen((state) {
        print('🔊 [DEBUG] Estado del player: $state');
      });

      // Iniciar reproducción en loop
      await _requestPlayer.play(source);
      print('🔊 [DEBUG] ✅ ¡Loop continuo iniciado!');

      print('🔊 [DEBUG] ==========================================');

    } catch (e, stackTrace) {
      print('❌ [ERROR] Error al iniciar loop de sonido: $e');
      print('❌ [STACK] $stackTrace');
      print('🔊 [DEBUG] ==========================================');

      // Marcar como error para no intentar más
      _hasError = true;
      _isPlayingRequestLoop = false;
    }
  }

  /// Reproduce un sonido de confirmación al aceptar un viaje
  static Future<void> playAcceptSound() async {
    // Vibración como feedback inmediato
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('❌ Error al vibrar: $e');
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

      print('🔊 Sonido de aceptación reproducido');
    } catch (e) {
      print('❌ Error al reproducir sonido de aceptación: $e');
    }
  }

  /// Detiene cualquier sonido que se esté reproduciendo
  static Future<void> stopSound() async {
    try {
      await _requestPlayer.stop();
      await _acceptPlayer.stop();
      _isPlayingRequestLoop = false; // Resetear el flag del loop
      print('🔊 [DEBUG] Sonidos detenidos y loop reseteado');
    } catch (e) {
      print('❌ Error al detener sonido: $e');
    }
  }

  /// Libera los recursos del reproductor de audio
  static Future<void> dispose() async {
    try {
      await _requestPlayer.dispose();
      await _acceptPlayer.dispose();
      _hasError = false;
    } catch (e) {
      print('❌ Error al liberar reproductor de audio: $e');
    }
  }
}
