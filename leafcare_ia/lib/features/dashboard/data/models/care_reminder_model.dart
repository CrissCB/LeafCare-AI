/// Representa un recordatorio de cuidado (regar, abonar, podar...).
///
/// Se construye a partir de un registro de la tabla `care_reminders` en Supabase.
class CareReminderModel {
  const CareReminderModel({
    required this.id,
    required this.action,
    required this.scheduledTime,
    required this.isCompleted,
    required this.isIaGenerated,
  });

  /// Identificador del registro en Supabase/PostgreSQL (UUID).
  final String id;

  /// Qué hay que hacer ("Regar", "Abonar", "Pulverizar"...).
  final String action;

  /// Fecha y hora en que toca el cuidado (ya convertida a hora local).
  final DateTime scheduledTime;

  /// Si el usuario ya marcó el cuidado como hecho.
  final bool isCompleted;

  /// Si el recordatorio lo generó la inteligencia artificial.
  final bool isIaGenerated;

  /// Convierte un mapa JSON de Supabase/PostgreSQL en un objeto de la aplicación.
  factory CareReminderModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['scheduled_time']?.toString() ?? '';
    final rawAction = json['treatment_action']?.toString().trim() ?? '';

    return CareReminderModel(
      id: json['id']?.toString() ?? '',
      action: rawAction.isNotEmpty ? rawAction : 'Cuidado de planta',
      scheduledTime: DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now(),
      isCompleted: json['is_completed'] == true,
      isIaGenerated: json['is_ia_generated'] == true,
    );
  }

  /// Convierte la instancia a un mapa JSON para inserciones o actualizaciones.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treatment_action': action,
      'scheduled_time': scheduledTime.toIso8601String(),
      'is_completed': isCompleted,
      'is_ia_generated': isIaGenerated,
    };
  }
}
