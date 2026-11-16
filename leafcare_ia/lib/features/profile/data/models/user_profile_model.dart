class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.providerLabel,
    required this.plantsCount,
    required this.scansCount,
    required this.alertsCount,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String providerLabel;
  final int plantsCount;
  final int scansCount;
  final int alertsCount;

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed[0].toUpperCase();
    if (email.trim().isNotEmpty) return email.trim()[0].toUpperCase();
    return 'U';
  }

  static String formatProvider(String? rawProvider) {
    switch (rawProvider?.toLowerCase().trim()) {
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      case 'github':
        return 'GitHub';
      default:
        return 'Correo electrónico';
    }
  }
}
