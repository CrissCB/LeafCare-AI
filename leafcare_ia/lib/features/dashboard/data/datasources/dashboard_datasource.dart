import 'dart:typed_data';

import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';

/// Se encarga de hablar con Supabase para la pantalla principal.
class DashboardDatasource {
  const DashboardDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Crea una planta nueva y sube su foto al bucket 'plant-photos' de Supabase Storage.
  Future<Map<String, dynamic>> createPlant({
    required String customName,
    required String scientificName,
    required String groupId,
    required List<int> imageBytes, // Funciona en Móvil y Web
    required String fileName,
  }) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    // 1. Subir la imagen a Supabase Storage
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final bytes = imageBytes is Uint8List
        ? imageBytes
        : Uint8List.fromList(imageBytes);

    await _client.storage.from('plant-photos').uploadBinary(path, bytes);

    final imageUrl = _client.storage.from('plant-photos').getPublicUrl(path);

    // 2. Insertar el registro de la planta en la tabla `user_plants`
    final response = await _client
        .from('user_plants')
        .insert({
          'user_id': userId,
          'group_id': groupId.isNotEmpty ? groupId : null,
          'custom_name': customName.trim(),
          'scientific_name': scientificName.trim(),
          'primary_image_url': imageUrl,
          'health_status_label': 'Sin evaluar',
          'health_status_color': '#64748B',
        })
        .select()
        .single();

    return response;
  }

  /// Devuelve el nombre del usuario que tiene la sesión abierta.
  Future<String> fetchUserName() async {
    final user = supabaseClient.currentUser;
    if (user == null) return 'Usuario';

    final userId = user.id;

    final profileData = await _client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .maybeSingle();

    final name =
        profileData?['name']?.toString().trim() ??
        user.userMetadata?['name']?.toString().trim() ??
        '';

    if (name.isNotEmpty) return name;

    // Si no hay nombre, usamos la parte del correo antes de la arroba.
    final email = user.email?.trim() ?? '';
    return email.isEmpty ? 'Usuario' : email.split('@').first;
  }

  /// Trae todas las plantas del usuario, de la más nueva a la más antigua.
  Future<List<UserPlantModel>> fetchPlants() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('user_plants')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((item) => UserPlantModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Cuenta las alertas de la IA que el usuario todavía no ha leído.
  Future<int> fetchUnreadAlertsCount() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return 0;

    final count = await _client
        .from('ia_alerts')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('is_read', false);

    return count;
  }

  /// Trae los recordatorios de hoy que aún no están completados.
  Future<List<CareReminderModel>> fetchTodayReminders() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('care_reminders')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .gte('scheduled_time', startOfDay.toIso8601String())
        .lt('scheduled_time', endOfDay.toIso8601String())
        .order('scheduled_time', ascending: true);

    final data = response as List<dynamic>;
    return data
        .map((item) => CareReminderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Marca un recordatorio como completado.
  Future<void> completeReminder(String reminderId) async {
    await _client
        .from('care_reminders')
        .update({'is_completed': true})
        .eq('id', reminderId);
  }
}
