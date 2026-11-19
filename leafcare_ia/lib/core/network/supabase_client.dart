export 'package:supabase_flutter/supabase_flutter.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabaseClient {
  const AppSupabaseClient();

  /// Acceso al cliente nativo de Supabase.
  SupabaseClient get client => Supabase.instance.client;

  /// Usuario autenticado en la sesión actual.
  User? get currentUser => client.auth.currentUser;

  /// ID del usuario actual (retorna null si no hay sesión activa).
  String? get currentUserId => currentUser?.id;

  /// Indica si hay una sesión de usuario activa.
  bool get isAuthenticated => currentUser != null;

  /// Acceso al módulo de autenticación (GoTrue).
  GoTrueClient get auth => client.auth;

  /// Acceso al módulo de almacenamiento de archivos (Storage).
  SupabaseStorageClient get storage => client.storage;
}
