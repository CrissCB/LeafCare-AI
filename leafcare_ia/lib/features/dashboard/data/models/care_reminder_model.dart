class CareReminderModel {
  const CareReminderModel({
    required this.id,
    this.userId,
    this.plantId,
    required this.treatmentAction,
    required this.scheduledTime,
    this.isRecurrent = false,
    this.isCompleted = false,
    this.isIaGenerated = false,
    this.snoozeHoursAdded = 0,
    this.createdAt,
    this.plantName,
    this.plantImageUrl,
  });

  final String id;
  final String? userId;
  final String? plantId;
  final String treatmentAction;
  final DateTime scheduledTime;
  final bool isRecurrent;
  final bool isCompleted;
  final bool isIaGenerated;
  final double snoozeHoursAdded;
  final DateTime? createdAt;

  // Campos resueltos si la consulta incluye `user_plants(custom_name, primary_image_url)`
  final String? plantName;
  final String? plantImageUrl;

  CareReminderModel copyWith({
    bool? isCompleted,
    DateTime? scheduledTime,
    double? snoozeHoursAdded,
  }) {
    return CareReminderModel(
      id: id,
      userId: userId,
      plantId: plantId,
      treatmentAction: treatmentAction,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isRecurrent: isRecurrent,
      isCompleted: isCompleted ?? this.isCompleted,
      isIaGenerated: isIaGenerated,
      snoozeHoursAdded: snoozeHoursAdded ?? this.snoozeHoursAdded,
      createdAt: createdAt,
      plantName: plantName,
      plantImageUrl: plantImageUrl,
    );
  }

  factory CareReminderModel.fromJson(Map<String, dynamic> json) {
    final plantJoin = json['user_plants'] is Map<String, dynamic>
        ? json['user_plants'] as Map<String, dynamic>
        : null;

    return CareReminderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      plantId: json['plant_id']?.toString(),
      treatmentAction: json['treatment_action'] as String? ?? 'Cuidado general',
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'].toString()).toLocal()
          : DateTime.now(),
      isRecurrent: json['is_recurrent'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      isIaGenerated: json['is_ia_generated'] as bool? ?? false,
      snoozeHoursAdded: (json['snooze_hours_added'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      plantName: plantJoin?['custom_name'] as String?,
      plantImageUrl: plantJoin?['primary_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson(String currentUserId) {
    return {
      'user_id': userId ?? currentUserId,
      'plant_id': plantId,
      'treatment_action': treatmentAction,
      'scheduled_time': scheduledTime.toUtc().toIso8601String(),
      'is_recurrent': isRecurrent,
      'is_completed': isCompleted,
      'is_ia_generated': isIaGenerated,
      'snooze_hours_added': snoozeHoursAdded,
    };
  }
}
