import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:leafcare_ia/core/network/pocketbase_client.dart';

class DashboardDatasource {
  Future<RecordModel> createPlant({
    required String customName,
    required String scientificName,
    required String groupId,
    required List<int> imageBytes, // Funciona en Móvil y Web
    required String fileName,
  }) async {
    final pb = await PocketBaseClient.getInstance();

    // Multipart/form-data para enviar la imagen a PocketBase y S3 Cloudflare
    final record = await pb
        .collection('user_plants')
        .create(
          body: {
            'user_id': pb.authStore.record!.id,
            'group_id': groupId,
            'custom_name': customName,
            'scientific_name': scientificName,
          },
          files: [
            http.MultipartFile.fromBytes(
              'primary_image_url',
              imageBytes,
              filename: fileName,
            ),
          ],
        );

    return record;
  }
}
