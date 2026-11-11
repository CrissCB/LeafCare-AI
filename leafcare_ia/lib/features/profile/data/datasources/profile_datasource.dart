import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';

/// Obtiene los datos del usuario con la sesión abierta.
class ProfileDatasource {
  Future<UserProfileModel> fetchProfile() async {
    final pb = await PocketBaseClient.getInstance();
    final record = pb.authStore.record;

    if (record == null) {
      return const UserProfileModel(
        name: 'Usuario',
        email: '',
        avatarUrl: '',
        providerLabel: 'Correo',
        plantsCount: 0,
        scansCount: 0,
        alertsCount: 0,
        memberSince: null,
      );
    }

    final data = record.data;
    final userId = record.id;

    // Contamos las plantas, escaneos y alertas del usuario.
    final plants = await pb.collection('user_plants').getList(
      page: 1,
      perPage: 1,
      filter: 'user_id = "$userId"',
    );
    final alerts = await pb.collection('ia_alerts').getList(
      page: 1,
      perPage: 1,
      filter: 'user_id = "$userId"',
    );
    final scans = await pb.collection('plant_scans').getList(
      page: 1,
      perPage: 1,
    );

    final name = data['name']?.toString().trim() ?? '';
    final email = data['email']?.toString().trim() ?? '';

    return UserProfileModel(
      name: name.isNotEmpty ? name : 'Usuario',
      email: email,
      avatarUrl: _avatarUrl(record.id, data['avatar']?.toString() ?? ''),
      providerLabel: _providerLabel(data['auth_provider']?.toString() ?? ''),
      plantsCount: plants.totalItems,
      scansCount: scans.totalItems,
      alertsCount: alerts.totalItems,
      memberSince: DateTime.tryParse(
        record.get<String>('created'),
      )?.toLocal(),
    );
  }

  /// Construye la dirección completa de la foto de perfil (si tiene).
  String _avatarUrl(String recordId, String fileName) {
    if (fileName.isEmpty) return '';
    return 'http://127.0.0.1:8082/api/files/users/$recordId/$fileName';
  }

  /// Traduce el método de registro a un texto entendible.
  String _providerLabel(String provider) {
    switch (provider) {
      case 'GOOGLE':
        return 'Google';
      case 'MICROSOFT':
        return 'Microsoft';
      default:
        return 'Correo';
    }
  }
}
