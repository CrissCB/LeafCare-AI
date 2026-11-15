class IaAlertModel {
  const IaAlertModel({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.scanId,
    required this.issueTitle,
    required this.shortDescription,
    required this.fullSummaryIa,
    required this.statusColor,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String plantId;
  final String scanId;
  final String issueTitle;
  final String shortDescription;
  final String fullSummaryIa;
  final String statusColor;
  final bool isRead;
  final DateTime? createdAt;

  factory IaAlertModel.fromJson(Map<String, dynamic> json) {
    return IaAlertModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      plantId: json['plant_id']?.toString() ?? '',
      scanId: json['scan_id']?.toString() ?? '',
      issueTitle: json['issue_title'] as String? ?? 'Alerta detectada',
      shortDescription: json['short_description'] as String? ?? '',
      fullSummaryIa: json['full_summary_ia'] as String? ?? '',
      statusColor: json['status_color'] as String? ?? '#F59E0B',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }
}
