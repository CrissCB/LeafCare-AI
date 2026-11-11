import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/account_model.dart';

/// Se encarga de leer y actualizar los datos de la cuenta.
class AccountDatasource {
  /// Trae los datos actuales del usuario con la sesión abierta.
  Future<AccountModel> fetchAccount() async {
    final pb = await PocketBaseClient.getInstance();
    final current = pb.authStore.record;

    if (current == null) {
      throw Exception('No hay una sesión abierta.');
    }

    // Pedimos el registro actualizado al servidor (no solo el guardado).
    final record = await pb.collection('users').getOne(current.id);
    final data = record.data;

    final name = data['name']?.toString().trim() ?? '';
    final email = data['email']?.toString().trim() ?? '';

    return AccountModel(
      id: record.id,
      name: name.isNotEmpty ? name : 'Usuario',
      email: email,
      providerLabel: _providerLabel(data['auth_provider']?.toString() ?? ''),
      memberSince: DateTime.tryParse(
        record.get<String>('created'),
      )?.toLocal(),
    );
  }

  /// Cambia el nombre del usuario y actualiza la sesión guardada.
  Future<void> updateName(String name) async {
    final pb = await PocketBaseClient.getInstance();
    final current = pb.authStore.record;

    if (current == null) {
      throw Exception('No hay una sesión abierta.');
    }

    final updated = await pb.collection('users').update(
      current.id,
      body: {'name': name.trim()},
    );

    // Guardamos el registro nuevo para que el nombre cambie en toda la app.
    pb.authStore.save(pb.authStore.token, updated);
  }

  /// Cambia la contraseña. PocketBase pide la contraseña actual.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final pb = await PocketBaseClient.getInstance();
    final current = pb.authStore.record;

    if (current == null) {
      throw Exception('No hay una sesión abierta.');
    }

    await pb.collection('users').update(
      current.id,
      body: {
        'oldPassword': oldPassword,
        'password': newPassword,
        'passwordConfirm': newPassword,
      },
    );
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
