class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.name,
    this.authProvider = 'NATIVE',
    this.avatarUrl,
    this.pushNotificationsEnabled = false,
    this.dailyEmailSummary = false,
    this.weeklyEmailSummary = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String authProvider;
  final String? avatarUrl;
  final bool pushNotificationsEnabled;
  final bool dailyEmailSummary;
  final bool weeklyEmailSummary;
  final DateTime? createdAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Usuario',
      authProvider: json['auth_provider'] as String? ?? 'NATIVE',
      avatarUrl: json['avatar_url'] as String?,
      pushNotificationsEnabled:
          json['push_notifications_enabled'] as bool? ?? false,
      dailyEmailSummary: json['daily_email_summary'] as bool? ?? false,
      weeklyEmailSummary: json['weekly_email_summary'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'auth_provider': authProvider,
      'avatar_url': avatarUrl,
      'push_notifications_enabled': pushNotificationsEnabled,
      'daily_email_summary': dailyEmailSummary,
      'weekly_email_summary': weeklyEmailSummary,
    };
  }
}
