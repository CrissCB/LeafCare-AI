import 'package:pocketbase/pocketbase.dart';

/// Representa un recordatorio de cuidado (regar, abonar, podar...).
///
/// Se construye a partir de un registro de la colección `care_reminders`.
class CareReminderModel {
  const CareReminderModel({
    required this.id,
    required this.action,
    required this.scheduledTime,
    required this.isCompleted,
    required this.isIaGenerated,
  });

  /// Identificador del registro en PocketBase.
  final String id;

  /// Qué hay que hacer ("Regar", "Abonar", "Pulverizar"...).
  final String action;

  /// Fecha y hora en que toca el cuidado (ya convertida a hora local).
  final DateTime scheduledTime;

  /// Si el usuario ya marcó el cuidado como hecho.
  final bool isCompleted;

  /// Si el recordatorio lo generó la inteligencia artificial.
  final bool isIaGenerated;

  /// Convierte un registro de PocketBase en un objeto de la aplicación.
  factory CareReminderModel.fromRecord(RecordModel record) {
    final data = record.data;
    final rawDate = data['scheduled_time']?.toString() ?? '';

    return CareReminderModel(
      id: record.id,
      action: (data['treatment_action']?.toString().trim().isNotEmpty ?? false)
          ? data['treatment_action'].toString().trim()
          : 'Cuidado de planta',
      scheduledTime:
          DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now(),
      isCompleted: data['is_completed'] == true,
      isIaGenerated: data['is_ia_generated'] == true,
    );
  }
}
