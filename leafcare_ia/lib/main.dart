import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:leafcare_ia/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las claves del archivo .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    dotenv.loadFromString(envString: '');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Inicializa Supabase con flujo PKCE para verificación de correo y recovery
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } else {
    debugPrint(
      '⚠️ Advertencia: Falta SUPABASE_URL o SUPABASE_ANON_KEY en el archivo .env',
    );
  }

  runApp(const LeafCareApp());
}
