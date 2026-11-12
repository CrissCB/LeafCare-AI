import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/security_model.dart';

/// Lee y guarda el estado de seguridad del usuario en Supabase.
class SecurityDatasource {
  const SecurityDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Trae el registro de `user_security`. Si no existe, lo crea.
  Future<SecurityModel> fetchSecurity() async {
    final userId = supabaseClient.currentUserId;

    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    final response = await _client
        .from('user_security')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      return _fromMap(response);
    }

    // Primera vez: creamos el registro con los valores por defecto.
    final created = await _client
        .from('user_security')
        .insert({
          'user_id': userId,
          'is_2fa_enabled': false,
          'two_factor_type': 'EMAIL',
          'failed_login_attempts': 0,
        })
        .select()
        .single();

    return _fromMap(created);
  }

  /// Activa o desactiva la verificación en dos pasos.
  Future<void> updateTwoFactor({
    required String recordId,
    required bool enabled,
    required String type,
  }) async {
    await _client
        .from('user_security')
        .update({'is_2fa_enabled': enabled, 'two_factor_type': type})
        .eq('id', recordId);
  }

  SecurityModel _fromMap(Map<String, dynamic> data) {
    final lockedRaw = data['locked_until']?.toString() ?? '';

    return SecurityModel(
      recordId: data['id']?.toString() ?? data['user_id']?.toString() ?? '',
      is2faEnabled: data['is_2fa_enabled'] == true,
      twoFactorType: data['two_factor_type']?.toString() ?? 'EMAIL',
      failedAttempts: (data['failed_login_attempts'] as num?)?.toInt() ?? 0,
      lockedUntil: lockedRaw.isEmpty
          ? null
          : DateTime.tryParse(lockedRaw)?.toLocal(),
    );
  }
}
