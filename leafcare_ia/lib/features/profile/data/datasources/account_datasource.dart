import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/account_model.dart';

/// Se encarga de leer y actualizar los datos de la cuenta en Supabase.
class AccountDatasource {
  const AccountDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Trae los datos actuales del usuario con la sesión abierta.
  Future<AccountModel> fetchAccount() async {
    final user = supabaseClient.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión abierta.');
    }

    // Consultar el perfil de la tabla 'profiles'
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final name =
        response?['name']?.toString().trim() ??
        user.userMetadata?['name']?.toString().trim() ??
        '';
    final email = user.email?.trim() ?? '';
    final provider = response?['auth_provider']?.toString() ?? '';
    final createdAtStr = response?['created_at']?.toString() ?? user.createdAt;

    return AccountModel(
      id: user.id,
      name: name.isNotEmpty ? name : 'Usuario',
      email: email,
      providerLabel: _providerLabel(provider),
      memberSince: DateTime.tryParse(createdAtStr)?.toLocal(),
    );
  }

  /// Cambia el nombre del usuario tanto en 'profiles' como en la metadata de Auth.
  Future<void> updateName(String name) async {
    final userId = supabaseClient.currentUserId;

    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    final cleanName = name.trim();

    // 1. Actualizar en la tabla public.profiles
    await _client.from('profiles').update({'name': cleanName}).eq('id', userId);

    // 2. Sincronizar metadata en Supabase Auth (GoTrue)
    await _client.auth.updateUser(UserAttributes(data: {'name': cleanName}));
  }

  /// Cambia la contraseña del usuario en Supabase Auth.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = supabaseClient.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión abierta.');
    }

    // Supabase actualiza la contraseña directamente en el usuario autenticado
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Traduce el método de registro a un texto entendible.
  String _providerLabel(String provider) {
    switch (provider.toUpperCase()) {
      case 'GOOGLE':
        return 'Google';
      case 'MICROSOFT':
        return 'Microsoft';
      default:
        return 'Correo';
    }
  }
}
