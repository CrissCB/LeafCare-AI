import 'package:flutter/foundation.dart';

/// Configuración de la aplicación para apuntar al backend local.
///
/// El backend (PocketBase) se levanta con Docker en http://127.0.0.1:8082.
class AppConfig {
  AppConfig._();

  /// URL base de PocketBase (publicado en el puerto 8082 del host).
  ///
  /// - Web: `127.0.0.1:8082`.
  /// - Emulador de Android: `10.0.2.2` hace referencia al localhost del equipo.
  /// - Simulador iOS / escritorio: `127.0.0.1`.
  static String get pocketBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8082';
    }
    return 'http://127.0.0.1:8082';
  }
}
