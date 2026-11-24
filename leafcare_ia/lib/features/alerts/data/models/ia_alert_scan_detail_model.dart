class IaAlertScanDetailModel {
  const IaAlertScanDetailModel({
    required this.scanId,
    required this.plantId,
    required this.scannedImageUrl,
    required this.customName,
    this.scientificName,
    required this.aiConfidencePercentage,
    required this.healthScore,
    required this.summaryKeyword,
    required this.healthDiagnosisText,
    required this.careInstructionsText,
    required this.suggestedActionText,
  });

  final String scanId;
  final String plantId;
  final String scannedImageUrl;
  final String customName;
  final String? scientificName;

  /// Valor entero entre 0 y 100 proveniente de `ai_confidence_percentage`.
  final int aiConfidencePercentage;

  /// Puntuación de salud entre 1 y 100 proveniente de `health_score`.
  final int healthScore;

  final String summaryKeyword;
  final String healthDiagnosisText;
  final String careInstructionsText;
  final String suggestedActionText;

  // Getters de compatibilidad para `IaAlertDetailSheet`
  int? get confidencePercent => aiConfidencePercentage;
  String? get scanImageUrl =>
      scannedImageUrl.isNotEmpty ? scannedImageUrl : null;

  factory IaAlertScanDetailModel.fromRecords({
    required Map<String, dynamic> scanJson,
    Map<String, dynamic>? plantJson,
    String? fallbackPlantName,
    String? fallbackPlantImage,
  }) {
    final rawScanImg = scanJson['scanned_image_url']?.toString().trim() ?? '';
    final rawPlantImg =
        plantJson?['primary_image_url']?.toString().trim() ?? '';

    final resolvedImage = rawScanImg.isNotEmpty
        ? rawScanImg
        : (rawPlantImg.isNotEmpty
              ? rawPlantImg
              : (fallbackPlantImage?.trim() ?? ''));

    final rawCustomName = plantJson?['custom_name']?.toString().trim() ?? '';
    final resolvedName = rawCustomName.isNotEmpty
        ? rawCustomName
        : ((fallbackPlantName?.trim().isNotEmpty == true)
              ? fallbackPlantName!.trim()
              : 'Planta monitoreada');

    final rawScientific =
        plantJson?['scientific_name']?.toString().trim() ?? '';

    final confidence =
        ((scanJson['ai_confidence_percentage'] as num?)?.round() ?? 0).clamp(
          0,
          100,
        );
    final score = ((scanJson['health_score'] as num?)?.round() ?? 100).clamp(
      1,
      100,
    );

    final healthText =
        (scanJson['health_diagnosis_text'] as String?)?.trim() ?? '';
    final careText =
        (scanJson['care_instructions_text'] as String?)?.trim() ?? '';
    final actionText =
        (scanJson['suggested_action_text'] as String?)?.trim() ?? '';

    return IaAlertScanDetailModel(
      scanId: scanJson['id']?.toString() ?? '',
      plantId:
          scanJson['plant_id']?.toString() ??
          plantJson?['id']?.toString() ??
          '',
      scannedImageUrl: resolvedImage,
      customName: resolvedName,
      scientificName: rawScientific.isNotEmpty ? rawScientific : null,
      aiConfidencePercentage: confidence,
      healthScore: score,
      summaryKeyword: (scanJson['summary_keyword'] as String?)?.trim() ?? '',
      healthDiagnosisText: healthText.isNotEmpty
          ? healthText
          : 'Sin observaciones detalladas registradas para este escaneo.',
      careInstructionsText: careText.isNotEmpty ? careText : 'Mantén los cuidados habituales de riego, luz y sustrato para esta especie.',
      suggestedActionText: actionText.isNotEmpty
          ? actionText
          : 'Monitorea la evolución de las hojas durante los próximos días.',
    );
  }
}
