import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/stats_model.dart';

/// Reúne los números que se muestran en la pantalla de estadísticas.
class StatsDatasource {
  /// Consulta plantas, análisis, alertas y recordatorios del usuario.
  Future<StatsModel> fetchStats() async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;

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

    final plants = await pb.collection('user_plants').getFullList(
      filter: 'user_id = "$userId"',
    );
    final scans = await pb.collection('plant_scans').getFullList(
      filter: 'plant_id.user_id = "$userId"',
      sort: '-created',
    );
    final alerts = await pb.collection('ia_alerts').getFullList(
      filter: 'user_id = "$userId"',
    );
    final reminders = await pb.collection('care_reminders').getFullList(
      filter: 'user_id = "$userId"',
    );

    // Mapa de id de planta a su nombre, para los análisis recientes.
    final plantNames = <String, String>{};
    for (final plant in plants) {
      plantNames[plant.id] = _text(plant.data['custom_name'], 'Mi planta');
    }

    // Contamos las plantas por estado de salud.
    final counts = <String, int>{};
    final colors = <String, String>{};

    for (final plant in plants) {
      final label = _text(plant.data['health_status_label'], 'Sin evaluar');
      final color = _text(plant.data['health_status_color'], '#64748B');

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

    // Los 5 análisis más recientes con el nombre de su planta.
    final recentScans = scans.take(5).map((scan) {
      final plantId = scan.data['plant_id']?.toString() ?? '';
      final created = scan.get<String>('created');

      return RecentScanStat(
        plantName: plantNames[plantId] ?? 'Planta',
        keyword: _text(scan.data['summary_keyword'], 'Análisis'),
        created:
            DateTime.tryParse(created)?.toLocal() ?? DateTime.now(),
        healthScore: _number(scan.data['health_score']).round(),
      );
    }).toList();

    final completed = reminders
        .where((reminder) => reminder.data['is_completed'] == true)
        .length;
    final unread = alerts
        .where((alert) => alert.data['is_read'] != true)
        .length;

    return StatsModel(
      plantsCount: plants.length,
      scansCount: scans.length,
      alertsCount: alerts.length,
      unreadAlerts: unread,
      remindersCount: reminders.length,
      completedReminders: completed,
      pendingReminders: reminders.length - completed,
      healthStats: healthStats,
      recentScans: recentScans,
    );
  }

  /// Devuelve el texto limpio o el valor por defecto si viene vacío.
  String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  /// Convierte un valor numérico de PocketBase en double.
  double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
