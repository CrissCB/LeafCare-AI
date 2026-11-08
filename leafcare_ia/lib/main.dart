import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:leafcare_ia/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las claves del archivo .env (Pl@ntNet y Perenual).
  // Si el archivo no existe, la app arranca igual, solo sin esas claves.
  try {
    await dotenv.load();
  } catch (_) {
    // Inicializamos vacío para que leer las claves no rompa la app.
    dotenv.loadFromString(envString: '');
  }

  runApp(const LeafCareApp());
}
