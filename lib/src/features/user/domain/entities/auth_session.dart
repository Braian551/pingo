import 'user.dart';

/// Entidad de Dominio: AuthSession
/// 
/// Representa una sesiÃ³n de autenticaciÃ³n activa.
/// Inmutable y sin dependencias de frameworks.
class AuthSession {
  final User user;
  final String? token;
  final DateTime? tokenExpiresAt;
  final DateTime loginAt;

  const AuthSession({
    required this.user,
    this.token,
    this.tokenExpiresAt,
    required this.loginAt,
  });

  /// ValidaciÃ³n: SesiÃ³n tiene token vÃ¡lido
  bool get hasToken => token != null && token!.isNotEmpty;

  /// ValidaciÃ³n: Token no ha expirado
  bool get isTokenValid {
    if (!hasToken) return false;
    if (tokenExpiresAt == null) return true; // Sin expiraciÃ³n definida
    return DateTime.now().isBefore(tokenExpiresAt!);
  }

  /// ValidaciÃ³n: SesiÃ³n es vÃ¡lida
  bool get isValid => hasToken && isTokenValid;

  /// Tiempo restante hasta expiraciÃ³n (null si no expira)
  Duration? get timeUntilExpiration {
    if (tokenExpiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(tokenExpiresAt!)) return Duration.zero;
    return tokenExpiresAt!.difference(now);
  }

  AuthSession copyWith({
    User? user,
    String? token,
    DateTime? tokenExpiresAt,
    DateTime? loginAt,
  }) {
    return AuthSession(
      user: user ?? this.user,
      token: token ?? this.token,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      loginAt: loginAt ?? this.loginAt,
    );
  }

  @override
  String toString() {
    return 'AuthSession(user: ${user.nombreCompleto}, isValid: $isValid)';
  }
}
