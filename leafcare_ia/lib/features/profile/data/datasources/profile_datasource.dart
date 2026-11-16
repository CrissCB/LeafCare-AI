import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';

class ProfileDatasource {
  const ProfileDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  Future<UserProfileModel> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    // Ejecuta las consultas en paralelo contra el esquema actual de Supabase
    final results = await Future.wait([
      _fetchProfileRow(user.id),
      _countUserPlants(user.id),
      _countUserScans(user.id),
      _countUserAlerts(user.id),
    ]);

    final profileRow = results[0] as Map<String, dynamic>?;
    final plantsCount = results[1] as int;
    final scansCount = results[2] as int;
    final alertsCount = results[3] as int;

    final metadata = user.userMetadata ?? const <String, dynamic>{};

    final rawName =
        (profileRow?['name'] ??
                profileRow?['full_name'] ??
                metadata['name'] ??
                metadata['full_name'])
            ?.toString()
            .trim();

    final email = (user.email ?? profileRow?['email']?.toString() ?? '').trim();

    final resolvedName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (email.contains('@') ? email.split('@').first : 'Usuario LeafCare');

    final resolvedAvatar =
        (profileRow?['avatar_url'] ??
                metadata['avatar_url'] ??
                metadata['picture'])
            ?.toString()
            .trim() ??
        '';

    final rawProvider = user.appMetadata['provider']?.toString();

    return UserProfileModel(
      id: user.id,
      name: resolvedName,
      email: email,
      avatarUrl: resolvedAvatar,
      providerLabel: UserProfileModel.formatProvider(rawProvider),
      plantsCount: plantsCount,
      scansCount: scansCount,
      alertsCount: alertsCount,
    );
  }

  Future<Map<String, dynamic>?> _fetchProfileRow(String userId) async {
    try {
      return await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<int> _countUserPlants(String userId) async {
    final response = await _client
        .from('user_plants')
        .select('id')
        .eq('user_id', userId);
    return (response as List<dynamic>).length;
  }

  Future<int> _countUserScans(String userId) async {
    // `plant_scans` se vincula al usuario mediante `plant_id -> user_plants.user_id`
    final response = await _client
        .from('plant_scans')
        .select('id, user_plants!inner(user_id)')
        .eq('user_plants.user_id', userId);
    return (response as List<dynamic>).length;
  }

  Future<int> _countUserAlerts(String userId) async {
    final response = await _client
        .from('ia_alerts')
        .select('id')
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    return (response as List<dynamic>).length;
  }
}
