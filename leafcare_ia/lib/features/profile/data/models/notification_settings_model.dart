class NotificationSettingsModel {
  const NotificationSettingsModel({
    required this.pushEnabled,
    required this.dailyEmailSummary,
    required this.weeklyEmailSummary,
    required this.userEmail,
  });

  final bool pushEnabled;
  final bool dailyEmailSummary;
  final bool weeklyEmailSummary;
  final String userEmail;

  int get activeCount =>
      (pushEnabled ? 1 : 0) +
      (dailyEmailSummary ? 1 : 0) +
      (weeklyEmailSummary ? 1 : 0);

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? dailyEmailSummary,
    bool? weeklyEmailSummary,
    String? userEmail,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      dailyEmailSummary: dailyEmailSummary ?? this.dailyEmailSummary,
      weeklyEmailSummary: weeklyEmailSummary ?? this.weeklyEmailSummary,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  factory NotificationSettingsModel.fromProfileRow({
    required Map<String, dynamic>? row,
    required String userEmail,
  }) {
    return NotificationSettingsModel(
      pushEnabled: row?['push_notifications_enabled'] as bool? ?? false,
      dailyEmailSummary: row?['daily_email_summary'] as bool? ?? false,
      weeklyEmailSummary: row?['weekly_email_summary'] as bool? ?? false,
      userEmail: userEmail.trim(),
    );
  }

  Map<String, dynamic> toProfileUpdateJson() {
    return {
      'push_notifications_enabled': pushEnabled,
      'daily_email_summary': dailyEmailSummary,
      'weekly_email_summary': weeklyEmailSummary,
    };
  }
}
