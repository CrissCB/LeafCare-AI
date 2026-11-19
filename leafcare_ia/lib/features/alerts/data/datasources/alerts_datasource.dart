import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/alerts/data/models/care_reminder_item_model.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_scan_detail_model.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_model.dart';

/// Fuente de datos para alertas IA y recordatorios de cuidado.
class AlertsDatasource {
  const AlertsDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Obtiene la URL del avatar y nombre del usuario para la cabecera decorativa.
  Future<({String userName, String? avatarUrl})> fetchUserHeaderInfo() async {
    final user = _client.auth.currentUser;
    if (user == null) return (userName: 'Usuario', avatarUrl: null);

    try {
      final profile = await _client
          .from('profiles')
          .select('name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      final name = (profile?['name'] as String?)?.trim().isNotEmpty == true
          ? (profile!['name'] as String).trim()
          : (user.userMetadata?['name'] as String?)?.trim() ?? 'Usuario';
      final avatar = (profile?['avatar_url'] as String?)?.trim();

      return (userName: name, avatarUrl: avatar);
    } catch (_) {
      final fallbackName =
          (user.userMetadata?['name'] as String?)?.trim() ?? 'Usuario';
      return (userName: fallbackName, avatarUrl: null);
    }
  }

  /// Obtiene las alertas IA activas y las eliminadas hace menos de 7 días.
  Future<List<IaAlertModel>> fetchIaAlerts() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final sevenDaysAgoIso = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 7))
        .toIso8601String();

    final response = await _client
        .from('ia_alerts')
        .select('*, user_plants(custom_name, primary_image_url)')
        .eq('user_id', userId)
        .or('deleted_at.is.null,deleted_at.gt.$sevenDaysAgoIso')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => IaAlertModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Obtiene el detalle del escaneo (`plant_scans`) y datos de la planta (`user_plants`).
  Future<IaAlertScanDetailModel> fetchAlertScanDetail(
    IaAlertModel alert,
  ) async {
    final results = await Future.wait([
      _client
          .from('plant_scans')
          .select(
            'id, plant_id, scanned_image_url, ai_confidence_percentage, '
            'health_score, summary_keyword, health_diagnosis_text, '
            'care_instructions_text, suggested_action_text',
          )
          .eq('id', alert.scanId)
          .single(),
      _client
          .from('user_plants')
          .select('id, custom_name, scientific_name, primary_image_url')
          .eq('id', alert.plantId)
          .maybeSingle(),
    ]);

    return IaAlertScanDetailModel.fromRecords(
      scanJson: results[0] as Map<String, dynamic>,
      fallbackPlantName: alert.plantName,
      fallbackPlantImage: alert.plantImageUrl,
    );
  }

  /// Marca una alerta IA como leída.
  Future<void> markIaAlertAsRead(String alertId) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    await _client
        .from('ia_alerts')
        .update({'is_read': true})
        .eq('id', alertId)
        .eq('user_id', userId);
  }

  /// Realiza borrado lógico de la alerta IA (permanece visible 7 días).
  Future<void> deleteIaAlert(String alertId) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    await _client
        .from('ia_alerts')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', alertId)
        .eq('user_id', userId);
  }

  /// Restaura una alerta IA eliminada limpiando `deleted_at`.
  Future<void> restoreIaAlert(String alertId) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    await _client
        .from('ia_alerts')
        .update({'deleted_at': null})
        .eq('id', alertId)
        .eq('user_id', userId);
  }

  /// Obtiene todos los recordatorios del usuario.
  Future<List<CareReminderItemModel>> fetchCareReminders() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final response = await _client
        .from('care_reminders')
        .select('*, user_plants(custom_name, primary_image_url)')
        .eq('user_id', userId)
        .order('scheduled_time', ascending: true);

    return (response as List<dynamic>)
        .map(
          (item) =>
              CareReminderItemModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  /// Obtiene las plantas del usuario con su grupo e imagen para el selector.
  Future<List<({String id, String name, String? imageUrl, String? groupId})>>
  fetchUserPlantOptions() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final response = await _client
        .from('user_plants')
        .select('id, custom_name, primary_image_url, group_id')
        .eq('user_id', userId)
        .order('custom_name', ascending: true);

    return (response as List<dynamic>)
        .map((item) {
          final map = item as Map<String, dynamic>;
          return (
            id: map['id']?.toString() ?? '',
            name: (map['custom_name'] as String?)?.trim().isNotEmpty == true
                ? (map['custom_name'] as String).trim()
                : 'Planta sin nombre',
            imageUrl: map['primary_image_url']?.toString().trim(),
            groupId: map['group_id']?.toString(),
          );
        })
        .toList(growable: false);
  }

  /// Obtiene los grupos del usuario para filtrar plantas al crear recordatorio.
  Future<List<({String id, String name, String iconName})>>
  fetchUserGroupOptions() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final response = await _client
        .from('plant_groups')
        .select('id, name, icon_name')
        .eq('user_id', userId)
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((item) {
          final map = item as Map<String, dynamic>;
          return (
            id: map['id']?.toString() ?? '',
            name: (map['name'] as String?)?.trim() ?? 'Grupo',
            iconName: map['icon_name']?.toString() ?? 'eco',
          );
        })
        .toList(growable: false);
  }

  /// Crea un nuevo recordatorio (frecuente entre 1 y 7 días, o único).
  Future<CareReminderItemModel> createReminder({
    required String plantId,
    required String treatmentAction,
    required String iconName,
    required DateTime scheduledTime,
    required bool isRecurrent,
    int? recurrenceDays,
  }) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) {
      throw Exception('No hay una sesión activa.');
    }

    final clampedDays = isRecurrent ? (recurrenceDays ?? 1).clamp(1, 7) : null;

    final response = await _client
        .from('care_reminders')
        .insert({
          'user_id': userId,
          'plant_id': plantId.trim(),
          'treatment_action': treatmentAction.trim(),
          'icon_name': iconName,
          'scheduled_time': scheduledTime.toUtc().toIso8601String(),
          'is_recurrent': isRecurrent,
          'recurrence_days': clampedDays,
          'is_completed': false,
          'is_ia_generated': false,
          'snooze_hours_added': 0,
        })
        .select('*, user_plants(custom_name, primary_image_url)')
        .single();

    return CareReminderItemModel.fromJson(response);
  }

  /// Edita un recordatorio existente (solo título, ícono, fecha/hora y frecuencia).
  Future<void> updateReminder({
    required String reminderId,
    required String treatmentAction,
    required String iconName,
    required DateTime scheduledTime,
    required bool isRecurrent,
    int? recurrenceDays,
  }) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    final clampedDays = isRecurrent ? (recurrenceDays ?? 1).clamp(1, 7) : null;

    await _client
        .from('care_reminders')
        .update({
          'treatment_action': treatmentAction.trim(),
          'icon_name': iconName,
          'scheduled_time': scheduledTime.toUtc().toIso8601String(),
          'is_recurrent': isRecurrent,
          'recurrence_days': clampedDays,
          'snooze_hours_added': 0,
        })
        .eq('id', reminderId)
        .eq('user_id', userId);
  }

  /// Marca como completado un recordatorio.
  Future<void> completeReminder(String reminderId) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    await _client
        .from('care_reminders')
        .update({'is_completed': true})
        .eq('id', reminderId)
        .eq('user_id', userId);
  }

  /// Pospone +1 hora un recordatorio dentro del mismo día.
  Future<void> snoozeReminderByOneHour(CareReminderItemModel reminder) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    final now = DateTime.now();
    if (!reminder.canSnoozeAt(now)) {
      throw StateError('Este recordatorio no se puede posponer ahora.');
    }

    final updatedTime = reminder.scheduledTime.add(const Duration(hours: 1));

    await _client
        .from('care_reminders')
        .update({
          'scheduled_time': updatedTime.toUtc().toIso8601String(),
          'snooze_hours_added': reminder.snoozeHoursAdded + 1,
        })
        .eq('id', reminder.id)
        .eq('user_id', userId);
  }

  /// Elimina un recordatorio.
  Future<void> deleteReminder(String reminderId) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    await _client
        .from('care_reminders')
        .delete()
        .eq('id', reminderId)
        .eq('user_id', userId);
  }
}
