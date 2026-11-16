import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/security_model.dart';

/// Datos necesarios para completar la vinculación de una app autenticadora.
class TotpEnrollmentData {
  const TotpEnrollmentData({
    required this.factorId,
    required this.secret,
    required this.qrCodeSvg,
    required this.uri,
  });

  final String factorId;
  final String secret;
  final String qrCodeSvg;
  final String uri;
}

class SecurityDatasource {
  const SecurityDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  Future<SecurityModel> fetchSecurity() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    var row = await _client
        .from('user_security')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

    // Respaldo: si el usuario no tenía fila en user_security, la inicializamos.
    row ??= await _client
        .from('user_security')
        .insert({
          'user_id': user.id,
          'is_2fa_enabled': false,
          'failed_login_attempts': 0,
        })
        .select('*')
        .single();

    String? verifiedTotpFactorId;
    try {
      final factors = await _client.auth.mfa.listFactors();
      for (final factor in factors.totp) {
        if (factor.status == FactorStatus.verified) {
          verifiedTotpFactorId = factor.id;
          break;
        }
      }
    } catch (_) {
      // Si MFA TOTP aún no está activo en el proyecto, continúa sin bloquear la pantalla.
    }

    final rawProvider =
        user.appMetadata['provider']?.toString().toLowerCase().trim() ??
        'email';
    final isExternal =
        rawProvider == 'google' ||
        rawProvider == 'microsoft' ||
        rawProvider == 'azure' ||
        rawProvider == 'apple';

    return SecurityModel(
      recordId: row['id']?.toString() ?? '',
      is2faEnabled: row['is_2fa_enabled'] as bool? ?? false,
      twoFactorType: row['two_factor_type']?.toString(),
      failedAttempts: (row['failed_login_attempts'] as num?)?.toInt() ?? 0,
      lockedUntil: DateTime.tryParse(row['locked_until']?.toString() ?? '')
          ?.toLocal(),
      userEmail: (user.email ?? '').trim(),
      isExternalProvider: isExternal,
      providerLabel: rawProvider == 'google'
          ? 'Google'
          : (rawProvider == 'microsoft' || rawProvider == 'azure')
          ? 'Microsoft'
          : 'Correo electrónico',
      lastSignInAt: DateTime.tryParse(user.lastSignInAt ?? '')?.toLocal(),
      verifiedTotpFactorId: verifiedTotpFactorId,
    );
  }

  /// Paso 1 (APP): Inicia el enrolamiento TOTP en Supabase Auth y obtiene secreto + SVG QR.
  Future<TotpEnrollmentData> startTotpEnrollment() async {
    // Limpiar factores TOTP previos sin verificar para evitar error de factor duplicado.
    final existing = await _client.auth.mfa.listFactors();
    for (final factor in existing.totp) {
      if (factor.status != FactorStatus.verified) {
        await _client.auth.mfa.unenroll(factor.id);
      }
    }

    final response = await _client.auth.mfa.enroll(
      factorType: FactorType.totp,
      friendlyName: 'LeafCare AI',
    );

    final totp = response.totp;
    if (totp == null) {
      throw Exception('No se pudo generar la clave de autenticación.');
    }

    return TotpEnrollmentData(
      factorId: response.id,
      secret: totp.secret,
      qrCodeSvg: totp.qrCode,
      uri: totp.uri,
    );
  }

  /// Paso 2 (APP): Verifica el código de 6 dígitos y guarda `APP` en `user_security`.
  Future<void> confirmTotpEnrollment({
    required String recordId,
    required String factorId,
    required String code,
  }) async {
    await _client.auth.mfa.challengeAndVerify(
      factorId: factorId,
      code: code.trim(),
    );

    await _client
        .from('user_security')
        .update({'is_2fa_enabled': true, 'two_factor_type': 'APP'})
        .eq('id', recordId);
  }

  /// Paso 1 (EMAIL): Envía un código OTP de 6 dígitos al correo del usuario.
  Future<void> sendEmailOtpCode(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
    );
  }

  /// Paso 2 (EMAIL): Valida el código recibido por correo y guarda `EMAIL` en `user_security`.
  Future<void> confirmEmailOtpAndEnable({
    required String recordId,
    required String email,
    required String code,
    String? previousTotpFactorId,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );

    // Si antes tenía una app autenticadora vinculada, la desvinculamos.
    if (previousTotpFactorId != null && previousTotpFactorId.isNotEmpty) {
      try {
        await _client.auth.mfa.unenroll(previousTotpFactorId);
      } catch (_) {}
    }

    await _client
        .from('user_security')
        .update({'is_2fa_enabled': true, 'two_factor_type': 'EMAIL'})
        .eq('id', recordId);
  }

  /// Desactiva el 2FA en `user_security` y elimina el factor TOTP si existía.
  Future<void> disableTwoFactor({
    required String recordId,
    String? verifiedTotpFactorId,
  }) async {
    if (verifiedTotpFactorId != null && verifiedTotpFactorId.isNotEmpty) {
      try {
        await _client.auth.mfa.unenroll(verifiedTotpFactorId);
      } catch (_) {}
    }

    await _client
        .from('user_security')
        .update({'is_2fa_enabled': false, 'two_factor_type': null})
        .eq('id', recordId);
  }

  /// Verifica la contraseña actual y actualiza a la nueva contraseña.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _client.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw Exception('No se encontró el correo de la cuenta.');
    }

    // Re-autenticar para confirmar identidad antes de cambiar la clave.
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Cierra todas las sesiones activas en otros dispositivos manteniendo la actual.
  Future<void> signOutOtherDevices() async {
    await _client.auth.signOut(scope: SignOutScope.others);
  }
}
