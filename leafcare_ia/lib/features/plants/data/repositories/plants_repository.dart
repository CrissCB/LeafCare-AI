import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/plants/data/datasources/plants_datasource.dart';
import 'package:leafcare_ia/features/plants/data/models/plant_group_model.dart';

class PlantsRepository {
  const PlantsRepository({required this.datasource});

  final PlantsDatasource datasource;

  /// Carga en paralelo las plantas y los grupos del usuario.
  Future<({List<UserPlantModel> plants, List<PlantGroupModel> groups})>
  loadPlantsAndGroups() async {
    final results = await Future.wait([
      datasource.fetchAllPlants(),
      datasource.fetchPlantGroups(),
    ]);

    return (
      plants: results[0] as List<UserPlantModel>,
      groups: results[1] as List<PlantGroupModel>,
    );
  }

  Future<PlantGroupModel> createGroup({
    required String name,
    required String iconName,
  }) {
    return datasource.createPlantGroup(name: name, iconName: iconName);
  }

  Future<PlantGroupModel> updateGroup({
    required String groupId,
    required String name,
    required String iconName,
  }) {
    return datasource.updatePlantGroup(
      groupId: groupId,
      name: name,
      iconName: iconName,
    );
  }

  Future<void> deleteGroup(String groupId) =>
      datasource.deletePlantGroup(groupId);

  Future<void> assignPlantToGroup({required String plantId, String? groupId}) {
    return datasource.assignPlantToGroup(plantId: plantId, groupId: groupId);
  }
}
