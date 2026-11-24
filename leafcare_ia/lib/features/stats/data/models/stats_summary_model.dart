import 'package:flutter/material.dart';
import 'package:leafcare_ia/app/config/app_theme.dart';

/// Categorías normalizadas del estado fitosanitario de una planta.
enum PlantConditionCategory { healthy, attention, sick, unassessed }

/// Representa un escaneo reciente para el historial de análisis.
class RecentScanItemModel {
  const RecentScanItemModel({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.scannedImageUrl,
    required this.healthScore,
    required this.aiConfidencePercentage,
    required this.summaryKeyword,
    required this.scanType,
    required this.createdAt,
  });

  final String id;
  final String plantId;
  final String plantName;
  final String scannedImageUrl;
  final int healthScore;
  final int aiConfidencePercentage;
  final String summaryKeyword;
  final String scanType;
  final DateTime createdAt;

  Color get scoreColor {
    if (healthScore >= 75) return AppColors.primary;
    if (healthScore >= 45) return const Color(0xFFF59E0B);
    return AppColors.error;
  }

  factory RecentScanItemModel.fromJson(Map<String, dynamic> json) {
    final plantMap = json['user_plants'];
    final plantName = (plantMap is Map<String, dynamic>)
        ? (plantMap['custom_name']?.toString().trim() ?? '')
        : '';

    return RecentScanItemModel(
      id: json['id']?.toString() ?? '',
      plantId: json['plant_id']?.toString() ?? '',
      plantName: plantName.isNotEmpty ? plantName : 'Planta registrada',
      scannedImageUrl: json['scanned_image_url']?.toString().trim() ?? '',
      healthScore: ((json['health_score'] as num?)?.round() ?? 100).clamp(
        1,
        100,
      ),
      aiConfidencePercentage:
          ((json['ai_confidence_percentage'] as num?)?.round() ?? 0).clamp(
            0,
            100,
          ),
      summaryKeyword:
          (json['summary_keyword'] as String?)?.trim().isNotEmpty == true
          ? (json['summary_keyword'] as String).trim()
          : 'Diagnóstico IA',
      scanType: json['scan_type']?.toString() ?? 'HEALTH_DIAGNOSIS',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Distribución de plantas por estado de salud.
class PlantHealthDistribution {
  const PlantHealthDistribution({
    required this.healthyCount,
    required this.attentionCount,
    required this.sickCount,
    required this.unassessedCount,
  });

  final int healthyCount;
  final int attentionCount;
  final int sickCount;
  final int unassessedCount;

  int get total => healthyCount + attentionCount + sickCount + unassessedCount;

  double ratioFor(int count) => total == 0 ? 0.0 : count / total;

  int percentFor(int count) => total == 0 ? 0 : ((count / total) * 100).round();
}

/// Resumen completo de métricas del jardín del usuario.
class StatsSummaryModel {
  const StatsSummaryModel({
    required this.totalPlants,
    required this.totalScans,
    required this.unreadIaAlerts,
    required this.readIaAlerts,
    required this.pendingReminders,
    required this.completedReminders,
    required this.averageHealthScore,
    required this.healthDistribution,
    required this.recentScans,
  });

  final int totalPlants;
  final int totalScans;
  final int unreadIaAlerts;
  final int readIaAlerts;
  final int pendingReminders;
  final int completedReminders;
  final int averageHealthScore;
  final PlantHealthDistribution healthDistribution;
  final List<RecentScanItemModel> recentScans;

  int get totalReminders => pendingReminders + completedReminders;
  int get totalActiveIaAlerts => unreadIaAlerts + readIaAlerts;

  /// Ratio (0.0 - 1.0) de recordatorios de cuidado completados.
  double get remindersCompletionRatio =>
      totalReminders == 0 ? 0.0 : completedReminders / totalReminders;

  int get remindersCompletionPercent =>
      (remindersCompletionRatio * 100).round();

  /// Ratio (0.0 - 1.0) de alertas IA revisadas.
  double get iaAlertsReviewedRatio =>
      totalActiveIaAlerts == 0 ? 0.0 : readIaAlerts / totalActiveIaAlerts;

  int get iaAlertsReviewedPercent => (iaAlertsReviewedRatio * 100).round();
}
