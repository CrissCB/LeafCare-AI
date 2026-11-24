import 'package:leafcare_ia/core/utils/reminder_icons.dart';

class CareReminderItemModel {
  const CareReminderItemModel({
    required this.id,
    required this.userId,
    this.plantId,
    required this.treatmentAction,
    required this.iconName,
    required this.scheduledTime,
    required this.isRecurrent,
    this.recurrenceDays,
    required this.isCompleted,
    required this.isIaGenerated,
    required this.snoozeHoursAdded,
    required this.createdAt,
    this.plantName,
    this.plantImageUrl,
  });

  final String id;
  final String userId;
  final String? plantId;
  final String treatmentAction;
  final String iconName;
  final DateTime scheduledTime;
  final bool isRecurrent;
  final int? recurrenceDays;
  final bool isCompleted;
  final bool isIaGenerated;
  final int snoozeHoursAdded;
  final DateTime createdAt;
  final String? plantName;
  final String? plantImageUrl;

  ReminderIconOption get iconOption =>
      ReminderIcons.resolve(iconName, fallbackAction: treatmentAction);

  bool get hasExtraHours => snoozeHoursAdded > 0;

  /// Fin del día calendario al que pertenece `scheduledTime` (23:59:59).
  DateTime get endOfScheduledDay => DateTime(
    scheduledTime.year,
    scheduledTime.month,
    scheduledTime.day,
    23,
    59,
    59,
  );

  /// `true` cuando finalizó el día programado sin haberse completado.
  bool isLateAt(DateTime now) {
    if (isCompleted) return false;
    return now.isAfter(endOfScheduledDay);
  }

  /// `true` mientras la hora extra añadida sigue corriendo y aún no se cumple.
  bool isSnoozeInProgressAt(DateTime now) {
    if (isCompleted || isLateAt(now)) return false;
    return snoozeHoursAdded > 0 && now.isBefore(scheduledTime);
  }

  /// `true` cuando el botón "+1 hora" está habilitado:
  /// - No está completado ni tardío (no ha terminado el día).
  /// - Si ya se pospuso antes, la hora extra ya se cumplió (`now >= scheduledTime`).
  /// - Sumar 1 hora más no cruza la medianoche hacia el día siguiente.
  bool canSnoozeAt(DateTime now) {
    if (isCompleted || isLateAt(now)) return false;
    if (isSnoozeInProgressAt(now)) return false;

    final nextTime = scheduledTime.add(const Duration(hours: 1));
    return !nextTime.isAfter(endOfScheduledDay);
  }

  factory CareReminderItemModel.fromJson(Map<String, dynamic> json) {
    String? resolvedPlantName;
    String? resolvedPlantImage;

    final plantData = json['user_plants'];
    if (plantData is Map<String, dynamic>) {
      resolvedPlantName = plantData['custom_name']?.toString().trim();
      resolvedPlantImage = plantData['primary_image_url']?.toString().trim();
    }

    final action =
        (json['treatment_action'] as String?)?.trim().isNotEmpty == true
        ? (json['treatment_action'] as String).trim()
        : 'Cuidado programado';

    return CareReminderItemModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      plantId: json['plant_id']?.toString(),
      treatmentAction: action,
      iconName:
          json['icon_name']?.toString() ??
          ReminderIcons.resolve(null, fallbackAction: action).key,
      scheduledTime:
          DateTime.tryParse(json['scheduled_time']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      isRecurrent: json['is_recurrent'] as bool? ?? false,
      recurrenceDays: (json['recurrence_days'] as num?)?.toInt(),
      isCompleted: json['is_completed'] as bool? ?? false,
      isIaGenerated: json['is_ia_generated'] as bool? ?? false,
      snoozeHoursAdded: (json['snooze_hours_added'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      plantName: resolvedPlantName,
      plantImageUrl: resolvedPlantImage,
    );
  }
}
