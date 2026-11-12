import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/stats_model.dart';

/// Reúne los números que se muestran en la pantalla de estadísticas en Supabase.
class StatsDatasource {
  const StatsDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Consulta plantas, análisis, alertas y recordatorios del usuario en paralelo.
  Future<StatsModel> fetchStats() async {
    final userId = supabaseClient.currentUserId;

    if (userId == null) {
      return const StatsModel(
        plantsCount: 0,
        scansCount: 0,
        alertsCount: 0,
        unreadAlerts: 0,
        remindersCount: 0,
        completedReminders: 0,
        pendingReminders: 0,
        healthStats: [],
        recentScans: [],
      );
    }

    // Consultar las 4 tablas necesarias concurrentemente con Future.wait
    final results = await Future.wait([
      _client
          .from('user_plants')
          .select('id, custom_name, health_status_label, health_status_color')
          .eq('user_id', userId),
      _client.from('ia_alerts').select('id, is_read').eq('user_id', userId),
      _client
          .from('care_reminders')
          .select('id, is_completed')
          .eq('user_id', userId),
      _client
          .from('plant_scans')
          .select(
            'id, plant_id, summary_keyword, health_score, created_at, user_plants!inner(user_id, custom_name)',
          )
          .eq('user_plants.user_id', userId)
          .order('created_at', ascending: false),
    ]);

    final List<dynamic> plantsData = results[0] as List<dynamic>;
    final List<dynamic> alertsData = results[1] as List<dynamic>;
    final List<dynamic> remindersData = results[2] as List<dynamic>;
    final List<dynamic> scansData = results[3] as List<dynamic>;

    // Mapa de ID de planta a su nombre
    final plantNames = <String, String>{};
    for (final plant in plantsData) {
      final pMap = plant as Map<String, dynamic>;
      final id = pMap['id']?.toString() ?? '';
      plantNames[id] = _text(pMap['custom_name'], 'Mi planta');
    }

    // Conteo por estado de salud
    final counts = <String, int>{};
    final colors = <String, String>{};

    for (final plant in plantsData) {
      final pMap = plant as Map<String, dynamic>;
      final label = _text(pMap['health_status_label'], 'Sin evaluar');
      final color = _text(pMap['health_status_color'], '#64748B');

      counts[label] = (counts[label] ?? 0) + 1;
      colors[label] = color;
    }

    final healthStats =
        counts.entries
            .map(
              (entry) => PlantHealthStat(
                label: entry.key,
                colorHex: colors[entry.key] ?? '#64748B',
                count: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    // Los 5 análisis más recientes relacionando la planta mediante el JOIN
    final recentScans = scansData.take(5).map((scan) {
      final sMap = scan as Map<String, dynamic>;
      final plantId = sMap['plant_id']?.toString() ?? '';
      final createdRaw = sMap['created_at']?.toString() ?? '';

      final joinedPlant = sMap['user_plants'] as Map<String, dynamic>?;
      final plantName = _text(
        joinedPlant?['custom_name'],
        plantNames[plantId] ?? 'Planta',
      );

      return RecentScanStat(
        plantName: plantName,
        keyword: _text(sMap['summary_keyword'], 'Análisis'),
        created: DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now(),
        healthScore: _number(sMap['health_score']).round(),
      );
    }).toList();

    final completed = remindersData
        .where((r) => (r as Map<String, dynamic>)['is_completed'] == true)
        .length;
    final unread = alertsData
        .where((a) => (a as Map<String, dynamic>)['is_read'] != true)
        .length;

    return StatsModel(
      plantsCount: plantsData.length,
      scansCount: scansData.length,
      alertsCount: alertsData.length,
      unreadAlerts: unread,
      remindersCount: remindersData.length,
      completedReminders: completed,
      pendingReminders: remindersData.length - completed,
      healthStats: healthStats,
      recentScans: recentScans,
    );
  }

  /// Devuelve el texto limpio o el valor por defecto si viene vacío.
  String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  /// Convierte un valor numérico en double.
  double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
