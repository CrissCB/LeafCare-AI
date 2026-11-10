/// Datos que se muestran en la pantalla de perfil.
class UserProfileModel {
  const UserProfileModel({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.providerLabel,
    required this.plantsCount,
    required this.scansCount,
    required this.alertsCount,
    required this.memberSince,
  });

  final String name;
  final String email;
  final String avatarUrl;

  /// Cómo se registró: "Correo", "Google" o "Microsoft".
  final String providerLabel;

  final int plantsCount;
  final int scansCount;
  final int alertsCount;

  /// Fecha de creación de la cuenta.
  final DateTime? memberSince;

  /// Primera letra del nombre, para cuando no hay foto.
  String get initial {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    return clean.substring(0, 1).toUpperCase();
  }
}
