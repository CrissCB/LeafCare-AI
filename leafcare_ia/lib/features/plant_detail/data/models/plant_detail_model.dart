import 'package:leafcare_ia/features/plant_detail/data/models/health_scan_model.dart';

class PlantDetailModel {
  const PlantDetailModel({
    // user_plants
    required this.id,
    required this.customName,
    required this.scientificName,
    required this.commonName,
    required this.speciesOrigin,
    required this.groupName,
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
  final String customName;
  final String scientificName;
  final String commonName;
  final String speciesOrigin;
  final String groupName;
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

  factory PlantDetailModel.fromPocketBase({
    required Map<String, dynamic> plantJson,
    required Map<String, dynamic> careJson,
    required List<HealthScanModel> scans,
  }) {
    // Si usas expand para traer el nombre del grupo
    String resolvedGroup = 'Sin grupo';
    final expand = plantJson['expand'];
    if (expand is Map<String, dynamic> && expand['group_id'] is Map) {
      resolvedGroup = (expand['group_id']['name'] as String?) ?? 'Sin grupo';
    }

    return PlantDetailModel(
      id: plantJson['id'] as String? ?? '',
      customName: plantJson['custom_name'] as String? ?? 'Mi Planta',
      scientificName: plantJson['scientific_name'] as String? ?? '',
      commonName: plantJson['common_name'] as String? ?? '',
      speciesOrigin:
          plantJson['species_origin'] as String? ?? 'No especificado',
      groupName: resolvedGroup,
      primaryImageUrl: plantJson['primary_image_url'] as String? ?? '',
      healthStatusLabel:
          plantJson['health_status_label'] as String? ?? 'Saludable',
      healthStatusColor:
          plantJson['health_status_color'] as String? ?? '#10B981',
      createdAt:
          DateTime.tryParse(plantJson['created'] as String? ?? '') ??
          DateTime.now(),

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
}
