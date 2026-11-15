class UserPlantModel {
  const UserPlantModel({
    required this.id,
    required this.userId,
    this.groupId,
    required this.customName,
    required this.scientificName,
    required this.commonName,
    this.speciesOrigin,
    this.externalSpeciesId,
    this.primaryImageUrl,
    required this.healthStatusLabel,
    required this.healthStatusColor,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? groupId;
  final String customName;
  final String scientificName;
  final String commonName;
  final String? speciesOrigin;
  final String? externalSpeciesId;
  final String? primaryImageUrl;
  final String healthStatusLabel;
  final String healthStatusColor;
  final DateTime? createdAt;

  factory UserPlantModel.fromJson(Map<String, dynamic> json) {
    return UserPlantModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      groupId: json['group_id']?.toString(),
      customName: json['custom_name'] as String? ?? 'Mi planta',
      scientificName: json['scientific_name'] as String? ?? '',
      commonName: json['common_name'] as String? ?? '',
      speciesOrigin: json['species_origin'] as String?,
      externalSpeciesId: json['external_species_id']?.toString(),
      primaryImageUrl: json['primary_image_url'] as String?,
      healthStatusLabel: json['health_status_label'] as String? ?? 'Saludable',
      healthStatusColor: json['health_status_color'] as String? ?? '#22C55E',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'custom_name': customName,
      'scientific_name': scientificName,
      'common_name': commonName,
      'species_origin': speciesOrigin,
      'external_species_id': externalSpeciesId,
      'primary_image_url': primaryImageUrl,
      'health_status_label': healthStatusLabel,
      'health_status_color': healthStatusColor,
    };
  }
}
