/// Preferencias de avisos que se guardan en la colección `users`.
class NotificationSettingsModel {
  const NotificationSettingsModel({
    required this.pushEnabled,
    required this.dailyEmail,
    required this.weeklyEmail,
  });

  /// Avisos dentro de la aplicación (notificaciones push).
  final bool pushEnabled;

  /// Resumen por correo todos los días.
  final bool dailyEmail;

  /// Resumen por correo una vez por semana.
  final bool weeklyEmail;

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? dailyEmail,
    bool? weeklyEmail,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      dailyEmail: dailyEmail ?? this.dailyEmail,
      weeklyEmail: weeklyEmail ?? this.weeklyEmail,
    );
  }
}
