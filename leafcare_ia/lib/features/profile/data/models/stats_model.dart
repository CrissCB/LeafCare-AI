/// Conteo de plantas por estado de salud.
class PlantHealthStat {
  const PlantHealthStat({
    required this.label,
    required this.colorHex,
    required this.count,
  });

  final String label;
  final String colorHex;
  final int count;
}

/// Resumen de un análisis reciente.
class RecentScanStat {
  const RecentScanStat({
    required this.plantName,
    required this.keyword,
    required this.created,
    required this.healthScore,
  });

  final String plantName;
  final String keyword;
  final DateTime created;
  final int healthScore;
}

/// Todos los datos que muestra la pantalla de estadísticas.
class StatsModel {
  const StatsModel({
    required this.plantsCount,
    required this.scansCount,
    required this.alertsCount,
    required this.unreadAlerts,
    required this.remindersCount,
    required this.completedReminders,
    required this.pendingReminders,
    required this.healthStats,
    required this.recentScans,
  });

  final int plantsCount;
  final int scansCount;
  final int alertsCount;
  final int unreadAlerts;
  final int remindersCount;
  final int completedReminders;
  final int pendingReminders;
  final List<PlantHealthStat> healthStats;
  final List<RecentScanStat> recentScans;

  /// Total de plantas contadas en los estados de salud.
  int get healthTotal =>
      healthStats.fold(0, (sum, item) => sum + item.count);
}
