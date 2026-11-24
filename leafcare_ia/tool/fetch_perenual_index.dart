import 'dart:convert';
import 'dart:io';

/// Script de una sola ejecución para indexar los 3.000 IDs gratuitos de Perenual.
/// Uso: dart run tool/fetch_perenual_index.dart TU_PERENUAL_API_KEY
Future<void> main(List<String> args) async {
  final apiKey = args.isNotEmpty
      ? args.first.trim()
      : (Platform.environment['PERENUAL_API_KEY'] ?? '').trim();

  if (apiKey.isEmpty) {
    stderr.writeln(
      'Falta la API Key.\nEjecuta: dart run tool/fetch_perenual_index.dart TU_API_KEY',
    );
    exit(1);
  }

  final outputFile = File('assets/data/perenual_index.json');
  await outputFile.parent.create(recursive: true);

  // Cargar progreso previo si el script se interrumpió antes
  int startPage = 1;
  final Map<String, int> indexMap = {};

  if (await outputFile.exists()) {
    try {
      final saved =
          jsonDecode(await outputFile.readAsString()) as Map<String, dynamic>;
      startPage = ((saved['last_completed_page'] as num?)?.toInt() ?? 0) + 1;
      final existingMap =
          saved['species_by_scientific_name'] as Map<String, dynamic>?;
      if (existingMap != null) {
        existingMap.forEach((k, v) => indexMap[k] = (v as num).toInt());
      }
      stdout.writeln(
        'Reanudando desde la página $startPage (${indexMap.length} nombres ya indexados)...',
      );
    } catch (_) {
      stdout.writeln('Iniciando índice desde cero...');
    }
  }

  const int maxPages = 100; // 100 páginas x 30 especies = 3.000 IDs gratuitos
  final client = HttpClient();

  try {
    for (int page = startPage; page <= maxPages; page++) {
      final uri = Uri.https('perenual.com', '/api/v2/species-list', {
        'key': apiKey,
        'page': '$page',
      });

      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 429) {
        stderr.writeln(
          '\nLímite de requests alcanzado en la página $page. '
          'Progreso guardado hasta la página ${page - 1}. Vuelve a ejecutar mañana.',
        );
        break;
      }

      if (response.statusCode != 200) {
        stderr.writeln(
          '\nError HTTP ${response.statusCode} en página $page: $body',
        );
        break;
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final data = (decoded['data'] as List<dynamic>?) ?? [];

      if (data.isEmpty) {
        stdout.writeln('\nNo hay más resultados en página $page. Finalizado.');
        break;
      }

      bool reachedLimitOver3000 = false;

      for (final rawItem in data) {
        final item = rawItem as Map<String, dynamic>;
        final id = (item['id'] as num?)?.toInt();
        if (id == null) continue;

        if (id > 3000) {
          reachedLimitOver3000 = true;
          continue;
        }

        final sciList = (item['scientific_name'] as List<dynamic>?) ?? [];
        for (final sci in sciList) {
          final normalized = _normalizeScientificName(sci.toString());
          if (normalized.isNotEmpty) {
            indexMap.putIfAbsent(normalized, () => id);
          }
        }
      }

      // Guardar progreso en disco tras cada página
      await _saveProgress(outputFile, page, indexMap);
      stdout.writeln(
        'Página $page/$maxPages completada | Nombres indexados: ${indexMap.length}',
      );

      if (reachedLimitOver3000) {
        stdout.writeln(
          'Se alcanzó el límite de ID <= 3000. Proceso terminado.',
        );
        break;
      }

      // Pausa breve para no saturar el servidor
      await Future.delayed(const Duration(milliseconds: 350));
    }
  } finally {
    client.close();
  }

  stdout.writeln('\nArchivo generado en: ${outputFile.path}');
}

/// Normaliza a minúsculas y conserva género + especie (ej. "Monstera deliciosa").
String _normalizeScientificName(String raw) {
  final cleaned = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return cleaned;
}

Future<void> _saveProgress(
  File file,
  int completedPage,
  Map<String, int> indexMap,
) async {
  final payload = {
    'last_completed_page': completedPage,
    'total_indexed_names': indexMap.length,
    'species_by_scientific_name': indexMap,
  };
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
}
