import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/stats/data/models/stats_summary_model.dart';

class StatsDatasource {
  const StatsDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  Future<StatsSummaryModel> fetchStatsSummary() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) {
      throw Exception('Sesión no iniciada');
    }

    final results = await Future.wait([
      _client
          .from('user_plants')
          .select('id, custom_name, health_status_label')
          .eq('user_id', userId),
      _client
          .from('plant_scans')
          .select(
            'id, plant_id, scan_type, scanned_image_url, '
            'ai_confidence_percentage, health_score, summary_keyword, '
            'created_at, user_plants!inner(user_id, custom_name)',
          )
          .eq('user_plants.user_id', userId)
          .order('created_at', ascending: false),
      _client
          .from('care_reminders')
          .select('id, is_completed')
          .eq('user_id', userId),
      _client
          .from('ia_alerts')
          .select('id, is_read')
          .eq('user_id', userId)
          .isFilter('deleted_at', null),
    ]);

    final plantsRows = (results[0] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final scansRows = (results[1] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final remindersRows = (results[2] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final alertsRows = (results[3] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    // 1. Último health_score por planta (como respaldo si health_status no está definido)
    final latestScoreByPlant = <String, int>{};
    int scoreAccumulator = 0;

    for (final scan in scansRows) {
      final plantId = scan['plant_id']?.toString() ?? '';
      final score = ((scan['health_score'] as num?)?.round() ?? 100).clamp(
        1,
        100,
      );
      scoreAccumulator += score;
      if (plantId.isNotEmpty && !latestScoreByPlant.containsKey(plantId)) {
        latestScoreByPlant[plantId] = score;
      }
    }

    final averageHealthScore = scansRows.isEmpty
        ? 0
        : (scoreAccumulator / scansRows.length).round().clamp(1, 100);

    // 2. Distribución de estados de salud de las plantas
    int healthy = 0;
    int attention = 0;
    int sick = 0;
    int unassessed = 0;

    for (final plant in plantsRows) {
      final plantId = plant['id']?.toString() ?? '';
      final rawStatus =
          plant['health_status_label']?.toString().toLowerCase().trim() ?? '';

      final category = _resolvePlantCondition(
        rawStatus: rawStatus,
        latestScanScore: latestScoreByPlant[plantId],
      );

      switch (category) {
        case PlantConditionCategory.healthy:
          healthy++;
        case PlantConditionCategory.attention:
          attention++;
        case PlantConditionCategory.sick:
          sick++;
        case PlantConditionCategory.unassessed:
          unassessed++;
      }
    }

    // 3. Recordatorios completados vs. pendientes
    int completedReminders = 0;
    int pendingReminders = 0;
    for (final reminder in remindersRows) {
      if (reminder['is_completed'] == true) {
        completedReminders++;
      } else {
        pendingReminders++;
      }
    }

    // 4. Alertas IA leídas vs. sin leer
    int readIaAlerts = 0;
    int unreadIaAlerts = 0;
    for (final alert in alertsRows) {
      if (alert['is_read'] == true) {
        readIaAlerts++;
      } else {
        unreadIaAlerts++;
      }
    }

    // 5. Últimos 6 escaneos realizados
    final recentScans = scansRows
        .take(6)
        .map(RecentScanItemModel.fromJson)
        .toList(growable: false);

    return StatsSummaryModel(
      totalPlants: plantsRows.length,
      totalScans: scansRows.length,
      unreadIaAlerts: unreadIaAlerts,
      readIaAlerts: readIaAlerts,
      pendingReminders: pendingReminders,
      completedReminders: completedReminders,
      averageHealthScore: averageHealthScore,
      healthDistribution: PlantHealthDistribution(
        healthyCount: healthy,
        attentionCount: attention,
        sickCount: sick,
        unassessedCount: unassessed,
      ),
      recentScans: recentScans,
    );
  }

  PlantConditionCategory _resolvePlantCondition({
    required String rawStatus,
    int? latestScanScore,
  }) {
    if (rawStatus.contains('salud') ||
        rawStatus.contains('health') ||
        rawStatus.contains('optimo') ||
        rawStatus.contains('good')) {
      return PlantConditionCategory.healthy;
    }
    if (rawStatus.contains('atenc') ||
        rawStatus.contains('atten') ||
        rawStatus.contains('warn') ||
        rawStatus.contains('moder')) {
      return PlantConditionCategory.attention;
    }
    if (rawStatus.contains('enferm') ||
        rawStatus.contains('crit') ||
        rawStatus.contains('sick') ||
        rawStatus.contains('urgen') ||
        rawStatus.contains('bad')) {
      return PlantConditionCategory.sick;
    }

    if (latestScanScore != null) {
      if (latestScanScore >= 75) return PlantConditionCategory.healthy;
      if (latestScanScore >= 45) return PlantConditionCategory.attention;
      return PlantConditionCategory.sick;
    }

    return PlantConditionCategory.unassessed;
  }
}
