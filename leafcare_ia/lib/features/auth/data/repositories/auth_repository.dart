import 'package:leafcare_ia/features/auth/data/models/auth_user_model.dart';

/// Resultado limpio de una operación de autenticación.
class AuthResult {
  const AuthResult({
    required this.userId,
    required this.email,
    required this.requiresEmailVerification,
  });

  final String userId;
  final String email;
  final bool requiresEmailVerification;
}

/// Excepción controlada del dominio con mensaje listo para la interfaz.
class AuthFailureException implements Exception {
  const AuthFailureException(this.message, {this.isEmailNotConfirmed = false});

  final String message;

  /// Indica si el fallo se debe a que el usuario aún no confirma su correo.
  final bool isEmailNotConfirmed;

  @override
  String toString() => message;
}

/// Contrato de autenticación que debe implementar la capa de datos.
abstract class AuthRepository {
  /// Inicia sesión con correo y contraseña.
  Future<AuthResult> login({required String email, required String password});

  /// Revisa si el usuario requiere verificación en dos pasos tras validar su clave.
  Future<TwoFactorChallenge?> checkTwoFactorRequirement({
    required String userId,
    required String email,
  });

  /// Verifica el código de 6 dígitos (App Autenticadora o Correo).
  Future<void> verifyTwoFactorCode({
    required TwoFactorChallenge challenge,
    required String code,
  });

  /// Reenvía el código de 6 dígitos al correo electrónico.
  Future<void> resendTwoFactorEmailCode(String email);

  /// Registra una cuenta nueva y dispara el correo de confirmación.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  });

  /// Reenvía el enlace de activación al correo electrónico.
  Future<void> resendVerificationEmail(String email);

  /// Envía el correo para restablecer la contraseña.
  Future<void> resetPassword(String email);

  /// Guarda la nueva contraseña tras abrir el enlace de recuperación.
  Future<void> updatePassword(String newPassword);

  /// Verifica si existe una sesión activa y válida.
  Future<bool> checkSession();

  /// Cierra la sesión actual.
  Future<void> logout();
}
