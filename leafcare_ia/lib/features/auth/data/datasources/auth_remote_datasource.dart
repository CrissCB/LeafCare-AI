import 'package:leafcare_ia/core/network/supabase_client.dart';

class AuthRemoteDatasource {
  const AuthRemoteDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Iniciar sesión con correo y contraseña
  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registro de usuario + inicialización de user_security
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final authResponse = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim(), 'auth_provider': 'NATIVE'},
    );

    final userId = authResponse.user?.id;

    if (userId != null) {
      try {
        await _client.from('user_security').insert({
          'user_id': userId,
          'is_2fa_enabled': false,
          'failed_login_attempts': 0,
        });
      } catch (_) {}
    }

    return authResponse;
  }

  /// Verificar si existe una sesión válida guardada en el dispositivo
  Future<bool> checkSession() async {
    final session = _client.auth.currentSession;
    if (session == null || session.isExpired) return false;

    try {
      final response = await _client.auth.getUser();
      return response.user != null;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// Cerrar sesión y limpiar tokens locales
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
