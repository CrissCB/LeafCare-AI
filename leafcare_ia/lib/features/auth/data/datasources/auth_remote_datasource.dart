import 'package:flutter/foundation.dart';

import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/auth/data/models/auth_user_model.dart';

class AuthRemoteDatasource {
  const AuthRemoteDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// URL de retorno tras hacer clic en enlaces de verificación o recuperación.
  String? get _redirectUrl {
    if (kIsWeb) return Uri.base.origin;
    return 'io.supabase.leafcare://login-callback/';
  }

  /// Iniciar sesión con correo y contraseña.
  /// Lanza [AuthException] con code == 'email_not_confirmed' si no ha verificado su correo.
  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Revisa si el usuario autenticado tiene 2FA activo en `public.user_security`.
  /// Devuelve `null` si puede entrar directo, o un [TwoFactorChallenge] si requiere código.
  Future<TwoFactorChallenge?> checkTwoFactorRequirement({
    required String userId,
    required String email,
  }) async {
    final row = await _client
        .from('user_security')
        .select('is_2fa_enabled, two_factor_type, locked_until')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;

    // Verificar si la cuenta está bloqueada temporalmente
    final lockedUntilStr = row['locked_until']?.toString();
    if (lockedUntilStr != null && lockedUntilStr.isNotEmpty) {
      final lockedUntil = DateTime.tryParse(lockedUntilStr);
      if (lockedUntil != null && lockedUntil.isAfter(DateTime.now().toUtc())) {
        await _client.auth.signOut();
        throw const AuthException(
          'Tu cuenta está bloqueada temporalmente por intentos fallidos. Intenta más tarde.',
        );
      }
    }

    // Limpiar contador de intentos fallidos tras un login exitoso
    await _client
        .from('user_security')
        .update({'failed_login_attempts': 0, 'locked_until': null})
        .eq('user_id', userId);

    final is2faEnabled = row['is_2fa_enabled'] as bool? ?? false;
    final type = row['two_factor_type']?.toString().toUpperCase();

    if (!is2faEnabled || type == null) return null;

    if (type == 'APP') {
      final factors = await _client.auth.mfa.listFactors();
      String? verifiedFactorId;
      for (final factor in factors.totp) {
        if (factor.status == FactorStatus.verified) {
          verifiedFactorId = factor.id;
          break;
        }
      }

      if (verifiedFactorId == null) return null;

      return TwoFactorChallenge(
        userId: userId,
        email: email,
        method: TwoFactorMethod.app,
        factorId: verifiedFactorId,
      );
    }

    if (type == 'EMAIL') {
      await _client.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );

      return TwoFactorChallenge(
        userId: userId,
        email: email,
        method: TwoFactorMethod.email,
      );
    }

    return null;
  }

  /// Verifica el código de 6 dígitos según el método configurado (`APP` o `EMAIL`).
  Future<void> verifyTwoFactorCode({
    required TwoFactorChallenge challenge,
    required String code,
  }) async {
    final cleanCode = code.trim();

    if (challenge.method == TwoFactorMethod.app) {
      final factorId = challenge.factorId;
      if (factorId == null || factorId.isEmpty) {
        throw const AuthException('Factor de autenticación no encontrado.');
      }
      await _client.auth.mfa.challengeAndVerify(
        factorId: factorId,
        code: cleanCode,
      );
      return;
    }

    await _client.auth.verifyOTP(
      email: challenge.email.trim(),
      token: cleanCode,
      type: OtpType.email,
    );
  }

  /// Reenvía el código de 6 dígitos cuando el método activo es EMAIL.
  Future<void> resendTwoFactorEmailCode(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
    );
  }

  /// Registro de usuario con envío de correo de verificación.
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    if (password != passwordConfirm) {
      throw const AuthException('Las contraseñas no coinciden.');
    }

    final authResponse = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim(), 'auth_provider': 'NATIVE'},
      emailRedirectTo: _redirectUrl,
    );

    final user = authResponse.user;
    if (user == null) {
      throw const AuthException('No se pudo completar el registro.');
    }

    // Supabase devuelve identities vacío si el correo ya estaba registrado
    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthException(
        'Este correo ya está registrado. Inicia sesión o revisa tu bandeja.',
      );
    }

    // Solo intenta insertar si ya hay sesión activa (ej. si desactivas verificación).
    // Si session == null, el trigger de PostgreSQL se encarga de crear user_security.
    if (authResponse.session != null) {
      try {
        await _client.from('user_security').insert({
          'user_id': user.id,
          'is_2fa_enabled': false,
          'two_factor_type': 'EMAIL',
          'failed_login_attempts': 0,
        });
      } catch (_) {}
    }

    return authResponse;
  }

  /// Reenvía el correo de verificación de cuenta.
  Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: _redirectUrl,
    );
  }

  /// Envía el correo con el enlace para restablecer la contraseña.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _redirectUrl,
    );
  }

  /// Guarda la nueva contraseña una vez el usuario ingresa desde el enlace de recuperación.
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Verificar si existe una sesión válida guardada en el dispositivo.
  Future<bool> checkSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return false;

    try {
      final response = await _client.auth.getUser();
      return response.user != null;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// Stream reactivo de cambios de sesión.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Cerrar sesión y limpiar tokens locales.
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
