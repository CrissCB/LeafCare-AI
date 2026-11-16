import 'dart:typed_data';

import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';

class ProfileDatasource {
  const ProfileDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  static const int maxAvatarBytes = 15 * 1024 * 1024; // 15 MB

  /// Actualiza el nombre y/o avatar del usuario (solo para cuentas de correo).
  Future<void> updateProfileDetails({
    required String name,
    Uint8List? avatarBytes,
    String fileExtension = 'jpg',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    final rawProvider = user.appMetadata['provider']
        ?.toString()
        .toLowerCase()
        .trim();
    if (rawProvider == 'google') {
      throw Exception(
        'Las cuentas vinculadas con Google se gestionan desde Google.',
      );
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre no puede estar vacío.');
    }

    String? newAvatarUrl;

    if (avatarBytes != null) {
      if (avatarBytes.lengthInBytes > maxAvatarBytes) {
        throw Exception('La imagen supera el límite máximo de 15 MB.');
      }

      final ext = _normalizeExtension(fileExtension);
      final mimeType = _mimeTypeFor(ext);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${user.id}/avatar_$timestamp.$ext';

      await _client.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            avatarBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      newAvatarUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    }

    // 1. Sincronizar metadata en Supabase Auth
    final updatedMetadata = <String, dynamic>{
      'name': cleanName,
      'full_name': cleanName,
      if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
    };

    await _client.auth.updateUser(UserAttributes(data: updatedMetadata));

    // 2. Sincronizar tabla `public.profiles` (si existe en el proyecto)
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'name': cleanName,
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      });
    } catch (_) {
      // Si la tabla `profiles` no existe o usa otra política, auth.users ya quedó actualizado.
    }
  }

  String _normalizeExtension(String rawExt) {
    final lower = rawExt.toLowerCase().replaceAll('.', '').trim();
    if (lower == 'png') return 'png';
    if (lower == 'webp') return 'webp';
    return 'jpg';
  }

  String _mimeTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<UserProfileModel> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

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

    final rawProvider = user.appMetadata['provider']
        ?.toString()
        .toLowerCase()
        .trim();

    return UserProfileModel(
      id: user.id,
      name: resolvedName,
      email: email,
      avatarUrl: resolvedAvatar,
      providerLabel: UserProfileModel.formatProvider(rawProvider),
      isGoogleAccount: rawProvider == 'google',
      plantsCount: plantsCount,
      scansCount: scansCount,
      alertsCount: alertsCount,
    );
  }

  /// Ejecuta el borrado definitivo de la cuenta del usuario autenticado.
  Future<void> deleteOwnAccount() async {
    await _client.rpc('delete_own_account');
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
