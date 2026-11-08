/// Datos de la cuenta que se pueden ver y editar en "Mi cuenta".
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.email,
    required this.providerLabel,
    required this.memberSince,
  });

  /// Identificador del usuario en PocketBase.
  final String id;

  /// Nombre que se muestra en la aplicación.
  final String name;

  /// Correo con el que se registró.
  final String email;

  /// Cómo se registró: "Correo", "Google" o "Microsoft".
  final String providerLabel;

  /// Fecha en la que se creó la cuenta.
  final DateTime? memberSince;

  /// Primera letra del nombre, para el círculo del avatar.
  String get initial {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    return clean.substring(0, 1).toUpperCase();
  }
}
