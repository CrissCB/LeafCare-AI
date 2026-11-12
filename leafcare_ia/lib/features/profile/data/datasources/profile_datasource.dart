import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';

/// Obtiene los datos del perfil y métricas del usuario en Supabase.
class ProfileDatasource {
  const ProfileDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  Future<UserProfileModel> fetchProfile() async {
    final user = supabaseClient.currentUser;

    if (user == null) {
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

    final userId = user.id;

    // 1. Obtener la información del perfil desde la tabla `profiles`
    final profileData = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    // 2. Contar plantas, alertas y escaneos del usuario en paralelo
    final counts = await Future.wait([
      _client
          .from('user_plants')
          .count(CountOption.exact)
          .eq('user_id', userId),
      _client.from('ia_alerts').count(CountOption.exact).eq('user_id', userId),
      _client
          .from('plant_scans')
          .count(CountOption.exact)
          .eq('user_id', userId),
    ]);

    final plantsCount = counts[0];
    final alertsCount = counts[1];
    final scansCount = counts[2];

    final name =
        profileData?['name']?.toString().trim() ??
        user.userMetadata?['name']?.toString().trim() ??
        '';
    final email = user.email?.trim() ?? '';
    final avatarRaw = profileData?['avatar_url']?.toString() ?? '';
    final providerRaw = profileData?['auth_provider']?.toString() ?? '';
    final createdAtStr =
        profileData?['created_at']?.toString() ?? user.createdAt;

    return UserProfileModel(
      name: name.isNotEmpty ? name : 'Usuario',
      email: email,
      avatarUrl: _avatarUrl(avatarRaw),
      providerLabel: _providerLabel(providerRaw),
      plantsCount: plantsCount,
      scansCount: scansCount,
      alertsCount: alertsCount,
      memberSince: DateTime.tryParse(createdAtStr)?.toLocal(),
    );
  }

  /// Procesa la URL del avatar (si es externa o reside en Supabase Storage)
  String _avatarUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Obtener la URL pública desde el bucket nativo de Supabase Storage
    return _client.storage.from('plant-photos').getPublicUrl(path);
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
