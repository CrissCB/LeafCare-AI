import 'package:supabase_flutter/supabase_flutter.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.isEmailVerified,
    this.avatarUrl = '',
  });

  final String id;
  final String email;
  final String name;
  final bool isEmailVerified;
  final String avatarUrl;

  /// Construye el modelo a partir del usuario de Supabase Auth y datos opcionales de `profiles`.
  factory AuthUserModel.fromSupabaseUser(
    User user, {
    Map<String, dynamic>? profileData,
  }) {
    final rawName =
        profileData?['name']?.toString().trim() ??
        user.userMetadata?['name']?.toString().trim() ??
        '';

    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      name: rawName.isNotEmpty
          ? rawName
          : (user.email?.split('@').first ?? 'Usuario'),
      isEmailVerified: user.emailConfirmedAt != null,
      avatarUrl: profileData?['avatar_url']?.toString() ?? '',
    );
  }
}
