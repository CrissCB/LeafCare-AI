import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/plants/data/models/plant_group_model.dart';

/// Fuente de datos para la colección completa de plantas y gestión de grupos.
class PlantsDatasource {
  const PlantsDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Obtiene todas las plantas del usuario ordenadas de más reciente a más antigua.
  Future<List<UserPlantModel>> fetchAllPlants() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final response = await _client
        .from('user_plants')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => UserPlantModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Obtiene todos los grupos creados por el usuario.
  Future<List<PlantGroupModel>> fetchPlantGroups() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return const [];

    final response = await _client
        .from('plant_groups')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((item) => PlantGroupModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Crea un nuevo grupo de plantas.
  Future<PlantGroupModel> createPlantGroup({
    required String name,
    required String iconName,
  }) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) {
      throw Exception('No hay una sesión activa.');
    }

    final response = await _client
        .from('plant_groups')
        .insert({'user_id': userId, 'name': name.trim(), 'icon_name': iconName})
        .select()
        .single();

    return PlantGroupModel.fromJson(response);
  }

  /// Actualiza el nombre o el ícono de un grupo existente.
  Future<PlantGroupModel> updatePlantGroup({
    required String groupId,
    required String name,
    required String iconName,
  }) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) {
      throw Exception('No hay una sesión activa.');
    }

    final response = await _client
        .from('plant_groups')
        .update({'name': name.trim(), 'icon_name': iconName})
        .eq('id', groupId)
        .eq('user_id', userId)
        .select()
        .single();

    return PlantGroupModel.fromJson(response);
  }

  /// Elimina un grupo (las plantas asociadas pasan automáticamente a `group_id = null`).
  Future<void> deletePlantGroup(String groupId) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    await _client
        .from('plant_groups')
        .delete()
        .eq('id', groupId)
        .eq('user_id', userId);
  }

  /// Asigna o quita (`groupId = null`) una planta de un grupo.
  Future<void> assignPlantToGroup({
    required String plantId,
    String? groupId,
  }) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return;

    await _client
        .from('user_plants')
        .update({'group_id': groupId})
        .eq('id', plantId)
        .eq('user_id', userId);
  }
}
