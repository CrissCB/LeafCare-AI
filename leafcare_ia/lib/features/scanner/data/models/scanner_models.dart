enum ScanMode {
  newRegistration, // Modalidad A -> 'NEW_REGISTRATION'
  healthDiagnosis, // Modalidad B -> 'HEALTH_DIAGNOSIS'
}

extension ScanModeX on ScanMode {
  String get dbValue => this == ScanMode.newRegistration
      ? 'NEW_REGISTRATION'
      : 'HEALTH_DIAGNOSIS';
}

/// Opción ligera de grupo (`public.plant_groups`) para el submenú desplegable.
class ScanGroupOption {
  const ScanGroupOption({required this.id, required this.name});

  final String id;
  final String name;

  factory ScanGroupOption.fromJson(Map<String, dynamic> json) {
    return ScanGroupOption(
      id: json['id'].toString(),
      name: (json['name'] ?? 'Grupo sin nombre').toString(),
    );
  }
}

/// Opción ligera de planta existente (`public.user_plants`) para Modalidad B.
class ScanPlantOption {
  const ScanPlantOption({
    required this.id,
    required this.groupId,
    required this.customName,
    required this.scientificName,
    required this.commonName,
    this.primaryImageUrl,
  });

  final String id;
  final String? groupId;
  final String customName;
  final String scientificName;
  final String commonName;
  final String? primaryImageUrl;

  factory ScanPlantOption.fromJson(Map<String, dynamic> json) {
    return ScanPlantOption(
      id: json['id'].toString(),
      groupId: json['group_id']?.toString(),
      customName: (json['custom_name'] ?? '').toString(),
      scientificName: (json['scientific_name'] ?? '').toString(),
      commonName: (json['common_name'] ?? '').toString(),
      primaryImageUrl: json['primary_image_url']?.toString(),
    );
  }
}

/// Resultado consolidado de Pl@ntNet + Perenual + Gemini
class ScanAnalysisResult {
  const ScanAnalysisResult({
    required this.mode,
    required this.groupId,
    required this.groupName,
    required this.localImagePath,
    required this.scientificName,
    required this.commonName,
    required this.aiConfidencePercentage,
    required this.healthScore,
    required this.healthStatusLabel,
    required this.healthStatusColorHex,
    required this.summaryKeyword,
    required this.healthDiagnosisText,
    required this.careInstructionsText,
    required this.suggestedActionText,
    required this.issueTitle,
    required this.shortDescription,
    required this.fullSummaryIa,
    this.existingPlantId,
    this.externalSpeciesId,
    this.speciesOrigin,
  });

  final ScanMode mode;
  final String groupId;
  final String groupName;
  final String localImagePath;

  // Datos taxonómicos y botánicos
  final String scientificName;
  final String commonName;
  final String? externalSpeciesId;
  final String? speciesOrigin;

  // Métricas de IA (alineadas con los CHECK de `plant_scans`)
  final double aiConfidencePercentage;
  final int healthScore;
  final String healthStatusLabel;
  final String healthStatusColorHex;
  final String summaryKeyword;

  // Los 3 bloques desplegables de la interfaz y columnas de `plant_scans`
  final String healthDiagnosisText;
  final String careInstructionsText;
  final String suggestedActionText;

  // Campos para `ia_alerts`
  final String issueTitle;
  final String shortDescription;
  final String fullSummaryIa;

  // Presente únicamente en Modalidad B (`HEALTH_DIAGNOSIS`)
  final String? existingPlantId;

  /// Umbral obligatorio del 50% de certeza.
  bool get meetsConfidenceThreshold => aiConfidencePercentage >= 50.0;
}

/// Parámetros opcionales para abrir `/scan` con contexto preseleccionado.
class ScannerRouteArgs {
  const ScannerRouteArgs({
    this.initialMode = ScanMode.newRegistration,
    this.initialGroupId,
    this.initialPlantId,
  });

  final ScanMode initialMode;
  final String? initialGroupId;
  final String? initialPlantId;
}
