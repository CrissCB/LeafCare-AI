import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/scanner/data/models/plant_identification_model.dart';

/// Guarda en PocketBase la planta que se identificó con la IA.
class ScannerDatasource {
  Future<void> savePlant({
    required String customName,
    required PlantIdentificationModel identification,
  }) async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;

    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    await pb.collection('user_plants').create(
      body: {
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
      },
    );
  }
}
