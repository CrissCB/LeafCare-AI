import 'package:flutter/material.dart';
import 'package:leafcare_ia/core/utils/health_status_colors.dart';

class IaAlertModel {
  const IaAlertModel({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.scanId,
    required this.issueTitle,
    required this.shortDescription,
    required this.fullSummaryIa,
    required this.statusColorHex,
    required this.isRead,
    required this.createdAt,
    this.deletedAt,
    this.plantName,
    this.plantImageUrl,
  });

  final String id;
  final String userId;
  final String plantId;
  final String scanId;
  final String issueTitle;
  final String shortDescription;
  final String fullSummaryIa;
  final String statusColorHex;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final String? plantName;
  final String? plantImageUrl;

  Color get statusColor => HealthStatusColors.fromHex(statusColorHex);

  bool get isDeleted => deletedAt != null;

  /// `true` si fue eliminada hace menos de 7 días.
  bool isWithinSevenDaysOfDeletion(DateTime now) {
    if (deletedAt == null) return false;
    return now.difference(deletedAt!).inDays < 7;
  }

  /// Etiqueta legible asociada al color de severidad.
  String get statusLabel {
    final normalized = statusColorHex.trim().toUpperCase();
    if (normalized.contains('EF4444') ||
        normalized.contains('DC2626') ||
        normalized.contains('E11D48')) {
      return 'Urgente';
    }
    if (normalized.contains('F59E0B') ||
        normalized.contains('D97706') ||
        normalized.contains('EAB308')) {
      return 'Atención';
    }
    if (normalized.contains('10B981') ||
        normalized.contains('059669') ||
        normalized.contains('22C55E')) {
      return 'Info';
    }
    return 'Alerta';
  }

  IaAlertModel copyWith({
    bool? isRead,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return IaAlertModel(
      id: id,
      userId: userId,
      plantId: plantId,
      scanId: scanId,
      issueTitle: issueTitle,
      shortDescription: shortDescription,
      fullSummaryIa: fullSummaryIa,
      statusColorHex: statusColorHex,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      plantName: plantName,
      plantImageUrl: plantImageUrl,
    );
  }

  factory IaAlertModel.fromJson(Map<String, dynamic> json) {
    String? resolvedPlantName;
    String? resolvedPlantImage;

    final plantData = json['user_plants'];
    if (plantData is Map<String, dynamic>) {
      resolvedPlantName = plantData['custom_name']?.toString().trim();
      resolvedPlantImage = plantData['primary_image_url']?.toString().trim();
    }

    final rawDeletedAt = json['deleted_at']?.toString();

    return IaAlertModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      plantId: json['plant_id']?.toString() ?? '',
      scanId: json['scan_id']?.toString() ?? '',
      issueTitle: (json['issue_title'] as String?)?.trim().isNotEmpty == true
          ? (json['issue_title'] as String).trim()
          : 'Alerta fitosanitaria',
      shortDescription: (json['short_description'] as String?)?.trim() ?? '',
      fullSummaryIa: (json['full_summary_ia'] as String?)?.trim() ?? '',
      statusColorHex:
          json['status_color']?.toString() ?? HealthStatusColors.attentionHex,
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      deletedAt: rawDeletedAt != null && rawDeletedAt.isNotEmpty
          ? DateTime.tryParse(rawDeletedAt)?.toLocal()
          : null,
      plantName: resolvedPlantName,
      plantImageUrl: resolvedPlantImage,
    );
  }
}
