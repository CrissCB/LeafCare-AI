import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/security_model.dart';

/// Lee y guarda el estado de seguridad del usuario.
class SecurityDatasource {
  /// Trae el registro de `user_security`. Si no existe, lo crea.
  Future<SecurityModel> fetchSecurity() async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;

    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    final records = await pb.collection('user_security').getFullList(
      filter: 'user_id = "$userId"',
    );

    if (records.isNotEmpty) {
      return _fromRecord(records.first);
    }

    // Primera vez: creamos el registro con los valores por defecto.
    final created = await pb.collection('user_security').create(
      body: {
        'user_id': userId,
        'is_2fa_enabled': false,
        'two_factor_type': 'EMAIL',
        'failed_login_attempts': 0,
      },
    );

    return _fromRecord(created);
  }

  /// Activa o desactiva la verificación en dos pasos.
  Future<void> updateTwoFactor({
    required String recordId,
    required bool enabled,
    required String type,
  }) async {
    final pb = await PocketBaseClient.getInstance();

    await pb.collection('user_security').update(
      recordId,
      body: {'is_2fa_enabled': enabled, 'two_factor_type': type},
    );
  }

  SecurityModel _fromRecord(RecordModel record) {
    final data = record.data;
    final lockedRaw = data['locked_until']?.toString() ?? '';

    return SecurityModel(
      recordId: record.id,
      is2faEnabled: data['is_2fa_enabled'] == true,
      twoFactorType: data['two_factor_type']?.toString() ?? 'EMAIL',
      failedAttempts: (data['failed_login_attempts'] as num?)?.toInt() ?? 0,
      lockedUntil: lockedRaw.isEmpty
          ? null
          : DateTime.tryParse(lockedRaw)?.toLocal(),
    );
  }
}
