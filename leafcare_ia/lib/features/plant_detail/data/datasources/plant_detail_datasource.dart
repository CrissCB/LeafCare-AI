import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
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

  /// Trae los recordatorios de cuidado de la planta.
  ///
  /// Primero aparecen los pendientes (por fecha) y al final los ya hechos.
  Future<List<CareReminderModel>> fetchReminders(String plantId) async {
    final pb = await PocketBaseClient.getInstance();

    final records = await pb.collection('care_reminders').getFullList(
      filter: 'plant_id = "$plantId"',
      sort: 'is_completed,scheduled_time',
    );

    return records.map(CareReminderModel.fromRecord).toList();
  }

  /// Cambia el nombre que el usuario le puso a su planta.
  Future<void> updatePlantName(String plantId, String newName) async {
    final pb = await PocketBaseClient.getInstance();

    await pb.collection('user_plants').update(
      plantId,
      body: {'custom_name': newName},
    );
  }

  /// Crea un recordatorio nuevo para la planta.
  Future<void> addReminder({
    required String plantId,
    required String action,
    required DateTime scheduledTime,
  }) async {
    final pb = await PocketBaseClient.getInstance();

    await pb.collection('care_reminders').create(
      body: {
        'user_id': pb.authStore.record!.id,
        'plant_id': plantId,
        'treatment_action': action,
        'scheduled_time': _toPocketBaseDate(scheduledTime),
        'is_recurrent': false,
        'is_completed': false,
        'is_ia_generated': false,
      },
    );
  }

  /// Marca un recordatorio como completado.
  Future<void> completeReminder(String reminderId) async {
    final pb = await PocketBaseClient.getInstance();

    await pb.collection('care_reminders').update(
      reminderId,
      body: {'is_completed': true},
    );
  }

  /// Borra un recordatorio.
  Future<void> deleteReminder(String reminderId) async {
    final pb = await PocketBaseClient.getInstance();

    await pb.collection('care_reminders').delete(reminderId);
  }

  /// Elimina una planta y todo lo que depende de ella.
  ///
  /// La base no tiene borrado en cascada, así que primero quitamos
  /// alertas, análisis y recordatorios para no dejar registros sueltos.
  Future<void> deletePlant(String plantId) async {
    final pb = await PocketBaseClient.getInstance();

    // 1. Alertas de la IA de esta planta
    final alerts = await pb.collection('ia_alerts').getFullList(
      filter: 'plant_id = "$plantId"',
    );
    for (final alert in alerts) {
      await pb.collection('ia_alerts').delete(alert.id);
    }

    // 2. Análisis (escaneos) de esta planta
    final scans = await pb.collection('plant_scans').getFullList(
      filter: 'plant_id = "$plantId"',
    );
    for (final scan in scans) {
      await pb.collection('plant_scans').delete(scan.id);
    }

    // 3. Recordatorios de cuidado
    final reminders = await pb.collection('care_reminders').getFullList(
      filter: 'plant_id = "$plantId"',
    );
    for (final reminder in reminders) {
      await pb.collection('care_reminders').delete(reminder.id);
    }

    // 4. Finalmente, la planta
    await pb.collection('user_plants').delete(plantId);
  }

  /// PocketBase espera las fechas con el formato "2026-11-07 08:00:00.000Z".
  String _toPocketBaseDate(DateTime date) {
    return date.toUtc().toIso8601String().replaceFirst('T', ' ');
  }
}
