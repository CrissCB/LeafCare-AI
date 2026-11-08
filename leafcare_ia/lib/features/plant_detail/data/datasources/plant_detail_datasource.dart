import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/plant_scan_model.dart';

/// Consultas para la pantalla de detalle de una planta.
class PlantDetailDatasource {
  /// Trae los datos de una planta por su identificador.
  Future<UserPlantModel> fetchPlant(String plantId) async {
    final pb = await PocketBaseClient.getInstance();
    final record = await pb.collection('user_plants').getOne(plantId);

    return UserPlantModel.fromRecord(record);
  }

  /// Trae el historial de análisis de la planta, del más nuevo al más viejo.
  Future<List<PlantScanModel>> fetchScans(String plantId) async {
    final pb = await PocketBaseClient.getInstance();

    final records = await pb.collection('plant_scans').getFullList(
      filter: 'plant_id = "$plantId"',
      sort: '-created',
    );

    return records.map(PlantScanModel.fromRecord).toList();
  }
}
