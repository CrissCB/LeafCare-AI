import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_profile_model.dart';

/// Fuente de datos de solo lectura para alimentar el resumen del Dashboard.
class DashboardDatasource {
  const DashboardDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Obtiene el perfil del usuario (nombre y avatar_url).
  Future<UserProfileModel> fetchUserProfile() async {
    final user = supabaseClient.currentUser;
    if (user == null) {
      return const UserProfileModel(id: '', name: 'Usuario');
    }

    final profileData = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileData != null) {
      return UserProfileModel.fromJson(profileData);
    }

    final metaName = user.userMetadata?['name']?.toString().trim() ?? '';
    final fallbackName = metaName.isNotEmpty
        ? metaName
        : (user.email?.split('@').first ?? 'Usuario');

    return UserProfileModel(
      id: user.id,
      name: fallbackName,
      avatarUrl: user.userMetadata?['avatar_url']?.toString(),
    );
  }

  /// Cuenta el total de plantas registradas por el usuario.
  Future<int> fetchTotalPlantsCount() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return 0;

    return _client
        .from('user_plants')
        .count(CountOption.exact)
        .eq('user_id', userId);
  }

  /// Obtiene las primeras N plantas del usuario (por defecto 5) para la vista previa.
  Future<List<UserPlantModel>> fetchTopPlants({int limit = 5}) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final response = await _client
        .from('user_plants')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((item) => UserPlantModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Cuenta las alertas de IA no leídas en `ia_alerts`.
  Future<int> fetchUnreadAlertsCount() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return 0;

    return _client
        .from('ia_alerts')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Obtiene los recordatorios pendientes del día actual (en hora local convertida a UTC)
  /// junto con el nombre e imagen de la planta asociada.
  Future<List<CareReminderModel>> fetchTodayReminders() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final now = DateTime.now();
    final startOfDayUtc = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDayUtc = startOfDayUtc.add(const Duration(days: 1));

    final response = await _client
        .from('care_reminders')
        .select('*, user_plants(custom_name, primary_image_url)')
        .eq('user_id', userId)
        .eq('is_completed', false)
        .gte('scheduled_time', startOfDayUtc.toIso8601String())
        .lt('scheduled_time', endOfDayUtc.toIso8601String())
        .order('scheduled_time', ascending: true);

    return (response as List<dynamic>)
        .map((item) => CareReminderModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
