class HealthScanModel {
  const HealthScanModel({
    required this.id,
    required this.plantId,
    required this.scanType,
    required this.scannedImageUrl,
    required this.aiConfidencePercentage,
    required this.healthScore,
    required this.summaryKeyword,
    required this.healthDiagnosisText,
    required this.careInstructionsText,
    required this.suggestedActionText,
    required this.createdAt,
  });

  final String id;
  final String plantId;
  final String scanType;
  final String scannedImageUrl;
  final double aiConfidencePercentage;
  final double healthScore;
  final String summaryKeyword;
  final String healthDiagnosisText;
  final String careInstructionsText;
  final String suggestedActionText;
  final DateTime createdAt;

  factory HealthScanModel.fromPocketBase(Map<String, dynamic> json) {
    return HealthScanModel(
      id: json['id'] as String? ?? '',
      plantId: json['plant_id'] as String? ?? '',
      scanType: json['scan_type'] as String? ?? 'UNKNOWN',
      scannedImageUrl: json['scanned_image_url'] as String? ?? '',
      aiConfidencePercentage:
          (json['ai_confidence_percentage'] as num?)?.toDouble() ?? 0.0,
      healthScore: (json['health_score'] as num?)?.toDouble() ?? 0.0,
      summaryKeyword: json['summary_keyword'] as String? ?? 'Sin diagnóstico',
      healthDiagnosisText: json['health_diagnosis_text'] as String? ?? '',
      careInstructionsText: json['care_instructions_text'] as String? ?? '',
      suggestedActionText: json['suggested_action_text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
