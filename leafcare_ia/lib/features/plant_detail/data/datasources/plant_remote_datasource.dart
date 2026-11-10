import 'package:leafcare_ia/core/network/pocketbase_client.dart';

class PlantRemoteDatasource {
  const PlantRemoteDatasource();

  Future<Map<String, dynamic>> getPlantById(String plantId) async {
    final pb = await PocketBaseClient.getInstance();
    final record = await pb
        .collection('user_plants')
        .getOne(plantId, expand: 'group_id');
    return record.toJson();
  }

  Future<Map<String, dynamic>> getCareDetailsByPlantId(String plantId) async {
    final pb = await PocketBaseClient.getInstance();
    final record = await pb
        .collection('plant_care_details')
        .getFirstListItem('plant_id = "$plantId"');
    return record.toJson();
  }

  Future<List<Map<String, dynamic>>> getPlantScansByPlantId(
    String plantId,
  ) async {
    final pb = await PocketBaseClient.getInstance();
    final records = await pb
        .collection('plant_scans')
        .getFullList(
          filter: 'plant_id = "$plantId"',
          sort: '-created', // Orden descendente (más recientes primero)
        );
    return records.map((r) => r.toJson()).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getUserGroups() async {
    final pb = await PocketBaseClient.getInstance();
    final records = await pb.collection('plant_groups').getFullList();
    return records.map((r) => r.toJson()).toList(growable: false);
  }

  Future<void> updatePlant({
    required String plantId,
    required String customName,
    String? groupId,
  }) async {
    final pb = await PocketBaseClient.getInstance();
    await pb
        .collection('user_plants')
        .update(
          plantId,
          body: {'custom_name': customName.trim(), 'group_id': groupId ?? ''},
        );
  }

  Future<void> deletePlant(String plantId) async {
    final pb = await PocketBaseClient.getInstance();
    await pb.collection('user_plants').delete(plantId);
  }
}
