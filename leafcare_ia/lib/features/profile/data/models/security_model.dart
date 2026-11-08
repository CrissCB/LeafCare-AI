/// Estado de seguridad del usuario (colección `user_security`).
class SecurityModel {
  const SecurityModel({
    required this.recordId,
    required this.is2faEnabled,
    required this.twoFactorType,
    required this.failedAttempts,
    required this.lockedUntil,
  });

  /// Identificador del registro en `user_security`.
  final String recordId;

  /// Si la verificación en dos pasos está activa.
  final bool is2faEnabled;

  /// Cómo se verifica: "EMAIL" o "APP".
  final String twoFactorType;

  /// Intentos de inicio de sesión fallidos.
  final int failedAttempts;

  /// Si la cuenta está bloqueada temporalmente, hasta cuándo.
  final DateTime? lockedUntil;

  /// Texto amigable del método de verificación.
  String get twoFactorLabel {
    switch (twoFactorType) {
      case 'APP':
        return 'Aplicación autenticadora';
      case 'EMAIL':
        return 'Correo electrónico';
      default:
        return 'Sin método elegido';
    }
  }

  /// Si la cuenta está bloqueada en este momento.
  bool get isLocked {
    final until = lockedUntil;
    return until != null && until.isAfter(DateTime.now());
  }
}
