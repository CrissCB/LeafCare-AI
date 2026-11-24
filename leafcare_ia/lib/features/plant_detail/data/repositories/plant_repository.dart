import 'package:leafcare_ia/features/plant_detail/data/datasources/plant_remote_datasource.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/health_scan_model.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/plant_detail_model.dart';

typedef JsonMap = Map<String, dynamic>;

class PlantRepository {
  const PlantRepository({required this.datasource});

  final PlantRemoteDatasource datasource;

  Future<PlantDetailModel> getFullPlantProfile(String plantId) async {
    final plantFuture = datasource.getPlantById(plantId);
    final careFuture = _safeGetCareDetails(plantId);
    final scansFuture = _safeGetPlantScans(plantId);

    final plantData = await plantFuture;
    final careData = await careFuture;
    final scansRaw = await scansFuture;

    final scans = scansRaw
        .map(HealthScanModel.fromPocketBase)
        .toList(growable: false);

    return PlantDetailModel.fromPocketBase(
      plantJson: plantData,
      careJson: careData,
      scans: scans,
    );
  }

  Future<List<JsonMap>> getUserGroups() async {
    try {
      return await datasource.getUserGroups();
    } catch (_) {
      return [];
    }
  }

  Future<void> updatePlant({
    required String plantId,
    required String customName,
    String? groupId,
  }) {
    return datasource.updatePlant(
      plantId: plantId,
      customName: customName,
      groupId: groupId,
    );
  }

  Future<void> deletePlant(String plantId) {
    return datasource.deletePlant(plantId);
  }

  Future<JsonMap> _safeGetCareDetails(String plantId) async {
    try {
      return await datasource.getCareDetailsByPlantId(plantId);
    } catch (_) {
      return {};
    }
  }

  Future<List<JsonMap>> _safeGetPlantScans(String plantId) async {
    try {
      return await datasource.getPlantScansByPlantId(plantId);
    } catch (_) {
      return [];
    }
  }
}
