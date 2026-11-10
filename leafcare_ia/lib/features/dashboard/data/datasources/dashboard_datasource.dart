import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';

/// Se encarga de hablar con PocketBase para la pantalla principal.
class DashboardDatasource {
  /// Crea una planta nueva y sube su foto a PocketBase (que la guarda en S3).
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

  /// Devuelve el nombre del usuario que tiene la sesión abierta.
  Future<String> fetchUserName() async {
    final pb = await PocketBaseClient.getInstance();
    final record = pb.authStore.record;

    if (record == null) return 'Usuario';

    final name = record.data['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;

    // Si no hay nombre, usamos la parte del correo antes de la arroba.
    final email = record.data['email']?.toString().trim() ?? '';
    return email.isEmpty ? 'Usuario' : email.split('@').first;
  }

  /// Trae todas las plantas del usuario, de la más nueva a la más antigua.
  Future<List<UserPlantModel>> fetchPlants() async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;
    if (userId == null) return [];

    final records = await pb.collection('user_plants').getFullList(
      filter: 'user_id = "$userId"',
      sort: '-created',
    );

    return records.map(UserPlantModel.fromRecord).toList();
  }

  /// Cuenta las alertas de la IA que el usuario todavía no ha leído.
  Future<int> fetchUnreadAlertsCount() async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;
    if (userId == null) return 0;

    final result = await pb.collection('ia_alerts').getList(
      page: 1,
      perPage: 1, // solo necesitamos el total, no los registros
      filter: 'user_id = "$userId" && is_read = false',
    );

    return result.totalItems;
  }

  /// Trae los recordatorios de hoy que aún no están completados.
  Future<List<CareReminderModel>> fetchTodayReminders() async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;
    if (userId == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final records = await pb.collection('care_reminders').getFullList(
      filter:
          'user_id = "$userId" && is_completed = false '
          '&& scheduled_time >= "${_toPocketBaseDate(startOfDay)}" '
          '&& scheduled_time < "${_toPocketBaseDate(endOfDay)}"',
      sort: 'scheduled_time',
    );

    return records.map(CareReminderModel.fromRecord).toList();
  }

  /// Marca un recordatorio como completado.
  Future<void> completeReminder(String reminderId) async {
    final pb = await PocketBaseClient.getInstance();

    await pb.collection('care_reminders').update(
      reminderId,
      body: {'is_completed': true},
    );
  }

  /// PocketBase espera las fechas con el formato "2026-11-07 08:00:00.000Z".
  String _toPocketBaseDate(DateTime date) {
    return date.toUtc().toIso8601String().replaceFirst('T', ' ');
  }
}
