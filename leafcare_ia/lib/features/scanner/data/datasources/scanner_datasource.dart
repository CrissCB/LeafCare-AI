import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/scanner/data/models/plant_identification_model.dart';

/// Guarda en Supabase la planta que se identificó con la IA.
class ScannerDatasource {
  const ScannerDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  Future<void> savePlant({
    required String customName,
    required PlantIdentificationModel identification,
  }) async {
    final userId = supabaseClient.currentUserId;

    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    await _client.from('user_plants').insert({
      'user_id': userId,
      'custom_name': customName,
      'scientific_name': identification.scientificName,
      'common_name': identification.commonName.isEmpty
          ? identification.scientificName
          : identification.commonName,
      'species_origin': identification.family,
      'external_species_id': identification.scientificName,
      'primary_image_url': identification.imageUrl,
      'health_status_label': 'Sin evaluar',
      'health_status_color': '#64748B',
    });
  }
}
