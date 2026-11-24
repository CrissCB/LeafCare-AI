import 'package:leafcare_ia/core/network/supabase_client.dart';

class PlantRemoteDatasource {
  const PlantRemoteDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  Future<Map<String, dynamic>> getPlantById(String plantId) async {
    final response = await _client
        .from('user_plants')
        .select('*, plant_groups(*)')
        .eq('id', plantId)
        .single();

    return response;
  }

  Future<Map<String, dynamic>> getCareDetailsByPlantId(String plantId) async {
    final response = await _client
        .from('plant_care_details')
        .select()
        .eq('plant_id', plantId)
        .maybeSingle();

    return response ?? {};
  }

  Future<List<Map<String, dynamic>>> getPlantScansByPlantId(
    String plantId,
  ) async {
    final response = await _client
        .from('plant_scans')
        .select()
        .eq('plant_id', plantId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserGroups() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('plant_groups')
        .select()
        .eq('user_id', userId)
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updatePlant({
    required String plantId,
    required String customName,
    String? groupId,
  }) async {
    final cleanGroupId = (groupId != null && groupId.isNotEmpty)
        ? groupId
        : null;

    await _client
        .from('user_plants')
        .update({'custom_name': customName.trim(), 'group_id': cleanGroupId})
        .eq('id', plantId);
  }

  Future<void> deletePlant(String plantId) async {
    await _client.from('user_plants').delete().eq('id', plantId);
  }
}
