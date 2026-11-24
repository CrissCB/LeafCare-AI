import 'package:leafcare_ia/features/plant_detail/data/models/health_scan_model.dart';

class PlantDetailModel {
  const PlantDetailModel({
    // user_plants
    required this.id,
    required this.customName,
    required this.scientificName,
    required this.commonName,
    required this.speciesOrigin,
    this.groupId,
    required this.groupName,
    this.groupIconName,
    required this.primaryImageUrl,
    required this.healthStatusLabel,
    required this.healthStatusColor,
    required this.createdAt,

    // plant_care_details
    required this.wateringFrequencyDays,
    required this.sunlightRequirement,
    required this.minTemp,
    required this.maxTemp,
    required this.humidity,
    required this.soilCharacteristics,
    required this.fertilizerCharacteristics,

    // plant_scans
    required this.scanHistory,
  });

  // Atributos user_plants
  final String id;
  final String? groupId;
  final String customName;
  final String scientificName;
  final String commonName;
  final String speciesOrigin;
  final String groupName;
  final String? groupIconName;
  final String primaryImageUrl;
  final String healthStatusLabel;
  final String healthStatusColor;
  final DateTime createdAt;

  // Atributos plant_care_details
  final double wateringFrequencyDays;
  final String sunlightRequirement;
  final double minTemp;
  final double maxTemp;
  final double humidity;
  final String soilCharacteristics;
  final String fertilizerCharacteristics;

  // Lista de historiales
  final List<HealthScanModel> scanHistory;

  factory PlantDetailModel.fromSupabase({
    required Map<String, dynamic> plantJson,
    required Map<String, dynamic> careJson,
    required List<HealthScanModel> scans,
  }) {
    String resolvedGroupName = 'Sin grupo';
    String? resolvedGroupIcon;

    // Supabase devuelve la relación bajo la clave del nombre de la tabla (`plant_groups`)
    final groupData = plantJson['plant_groups'];
    if (groupData is Map<String, dynamic>) {
      final rawName = groupData['name']?.toString().trim();
      if (rawName != null && rawName.isNotEmpty) {
        resolvedGroupName = rawName;
      }
      resolvedGroupIcon = groupData['icon_name']?.toString();
    }

    final rawCreated =
        plantJson['created_at']?.toString() ?? plantJson['created']?.toString();

    return PlantDetailModel(
      id: plantJson['id']?.toString() ?? '',
      groupId: plantJson['group_id']?.toString(),
      customName: plantJson['custom_name'] as String? ?? 'Mi Planta',
      scientificName: plantJson['scientific_name'] as String? ?? '',
      commonName: plantJson['common_name'] as String? ?? '',
      speciesOrigin:
          plantJson['species_origin'] as String? ?? 'No especificado',
      groupName: resolvedGroupName,
      groupIconName: resolvedGroupIcon,
      primaryImageUrl: plantJson['primary_image_url'] as String? ?? '',
      healthStatusLabel:
          plantJson['health_status_label'] as String? ?? 'Sin evaluar',
      healthStatusColor:
          plantJson['health_status_color'] as String? ?? '#64748B',
      createdAt:
          DateTime.tryParse(rawCreated ?? '')?.toLocal() ?? DateTime.now(),

      wateringFrequencyDays:
          (careJson['watering_frequency_days'] as num?)?.toDouble() ?? 7.0,
      sunlightRequirement:
          careJson['sunlight_requirement'] as String? ?? 'Luz indirecta',
      minTemp: (careJson['min_temperature_c'] as num?)?.toDouble() ?? 18.0,
      maxTemp: (careJson['max_temperature_c'] as num?)?.toDouble() ?? 27.0,
      humidity: (careJson['humidity_percentage'] as num?)?.toDouble() ?? 60.0,
      soilCharacteristics:
          careJson['soil_characteristics'] as String? ?? 'Sustrato universal',
      fertilizerCharacteristics:
          careJson['fertilizer_characteristics'] as String? ?? 'Abono líquido',

      scanHistory: scans,
    );
  }

  /// Alias temporal para mantener compatibilidad con `PlantRepository`.
  factory PlantDetailModel.fromPocketBase({
    required Map<String, dynamic> plantJson,
    required Map<String, dynamic> careJson,
    required List<HealthScanModel> scans,
  }) {
    return PlantDetailModel.fromSupabase(
      plantJson: plantJson,
      careJson: careJson,
      scans: scans,
    );
  }
}
