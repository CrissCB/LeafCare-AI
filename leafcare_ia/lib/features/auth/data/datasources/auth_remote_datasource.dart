import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/core/network/pocketbase_client.dart';

class AuthRemoteDatasource {
  /// Iniciar sesión con correo y contraseña
  Future<RecordAuth> login(String email, String password) async {
    final pb = await PocketBaseClient.getInstance();
    return await pb.collection('users').authWithPassword(email, password);
  }

  /// Registro de usuario + inicialización de user_security
  Future<RecordAuth> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final pb = await PocketBaseClient.getInstance();

    // 1. Crear el usuario en la colección 'users'
    final userRecord = await pb
        .collection('users')
        .create(
          body: {
            'name': name,
            'email': email,
            'password': password,
            'passwordConfirm': passwordConfirm,
            'emailVisibility': true,
            'auth_provider': 'NATIVE',
            'push_notifications_enabled': true,
            'daily_email_summary': false,
            'weekly_email_summary': true,
          },
        );

    // 2. Iniciar sesión automáticamente tras el registro
    final authData = await pb
        .collection('users')
        .authWithPassword(email, password);

    // 3. Crear el registro en 'user_security' vinculado al usuario creado
    try {
      await pb
          .collection('user_security')
          .create(
            body: {
              'user_id': userRecord.id,
              'is_2fa_enabled': false,
              'failed_login_attempts': 0,
              'last_login': DateTime.now().toIso8601String(),
            },
          );
    } catch (_) {}

    return authData;
  }

  /// Verificar si existe una sesión válida guardada en el dispositivo
  Future<bool> checkSession() async {
    final pb = await PocketBaseClient.getInstance();
    if (!pb.authStore.isValid) return false;

    try {
      // Revalida el token contra el servidor PocketBase
      await pb.collection('users').authRefresh();
      return true;
    } catch (_) {
      pb.authStore.clear();
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    final pb = await PocketBaseClient.getInstance();
    pb.authStore.clear();
  }
}
