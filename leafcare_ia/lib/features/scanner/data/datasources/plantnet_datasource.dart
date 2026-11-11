import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:leafcare_ia/core/constants/api_constants.dart';
import 'package:leafcare_ia/features/scanner/data/models/plant_identification_model.dart';

/// Se comunica con la API de Pl@ntNet para identificar una planta.
class PlantNetDatasource {
  /// Envía la foto y devuelve la lista de especies candidatas.
  Future<List<PlantIdentificationModel>> identify({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final apiKey = ApiConstants.plantNetApiKey;

    // Si la clave no se cargó, avisamos con un mensaje claro.
    if (apiKey.isEmpty || apiKey == 'PLANTNET_API_KEY') {
      throw const PlantNetException(
        'Falta la clave de Pl@ntNet. Revisa el archivo .env',
      );
    }

    final uri = Uri.parse(
      '${ApiConstants.plantNetIdentifyUrl}?api-key=$apiKey&lang=es',
    );

    // La API recibe la imagen como formulario multipart.
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytes,
          filename: fileName,
        ),
      )
      ..fields['organs'] = 'auto';

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const PlantNetException(
        'La clave de Pl@ntNet no es válida o se agotó la cuota.',
      );
    }

    if (response.statusCode == 404) {
      throw const PlantNetException(
        'No se reconoció ninguna planta en la foto. Intenta con otra imagen.',
      );
    }

    if (response.statusCode != 200) {
      throw PlantNetException(
        'El servicio respondió con un error (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (decoded['results'] as List?) ?? const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(PlantIdentificationModel.fromJson)
        .toList();
  }
}
