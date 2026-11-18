import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ---------------------------------------------------------------------------
  // 1. Pl@ntNet API (Identificación visual de especies)
  // ---------------------------------------------------------------------------
  static const String plantNetBaseUrl = 'https://my-api.plantnet.org/v2';
  static const String plantNetIdentifyEndpoint = '/identify/all';
  static const String plantNetDefaultLang = 'es';

  static String get plantNetApiKey =>
      (dotenv.env['PLANTNET_API_KEY'] ?? '').trim();

  // ---------------------------------------------------------------------------
  // 2. Perenual API (Fichas botánicas y cuidados)
  // ---------------------------------------------------------------------------
  static const String perenualBaseUrl = 'https://perenual.com/api/v2';
  static const String perenualSpeciesListEndpoint = '/species-list';
  static const String perenualSpeciesDetailsEndpoint = '/species/details';

  static String get perenualApiKey =>
      (dotenv.env['PERENUAL_API_KEY'] ?? '').trim();

  /// Límite de IDs disponibles sin costo en el plan gratuito de Perenual.
  static const int perenualMaxFreeId = 3000;

  /// Recurso local generado por `tool/fetch_perenual_index.dart` para validar
  /// existencia de especies antes de consultar la API.
  static const String perenualIndexAssetPath =
      'assets/data/perenual_index.json';

  // ---------------------------------------------------------------------------
  // 3. Google AI Studio / Gemini API (Diagnóstico fitosanitario y estrés)
  // ---------------------------------------------------------------------------
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiVisionModel = 'gemini-2.5-flash';
  static const String geminiFallbackModel = 'gemini-2.5-flash-lite';

  static String get geminiApiKey => (dotenv.env['GEMINI_API_KEY'] ?? '').trim();

  /// Construye la URI completa de generación para el modelo indicado.
  static Uri geminiGenerateContentUri([String model = geminiVisionModel]) {
    return Uri.parse(
      '$geminiBaseUrl/models/$model:generateContent?key=$geminiApiKey',
    );
  }

  // Feed de jardinería en español
  static const String gardeningRssUrl = 'https://www.jardineriaon.com/feed';
}
