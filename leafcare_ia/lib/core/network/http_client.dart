import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente HTTP para APIs de terceros (RSS, Pl@ntNet, Perenual).
class AppHttpClient {
  const AppHttpClient();

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta no es un objeto JSON');
    }
    return decoded;
  }
}
