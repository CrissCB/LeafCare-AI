import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Endpoints APIs Externas
  static const String plantNetIdentifyUrl =
      'https://my-api.plantnet.org/v2/identify/all';
  static const String plantNetDiseasesUrl =
      'https://my-api.plantnet.org/v2/diseases/identify';

  // API Key for PlantNet API, retrieved from environment variables
  static final String plantNetApiKey =
      dotenv.env['PLANTNET_API_KEY'] ?? 'PLANTNET_API_KEY';

  static const String perenualSpeciesUrl =
      'https://perenual.com/api/species-list';

  // API Key for Perenual API, retrieved from environment variables
  static final String perenualApiKey =
      dotenv.env['PERENUAL_API_KEY'] ?? 'PERENUAL_API_KEY';

  // Feed de jardinería en español
  static const String gardeningRssUrl = 'https://www.jardineriaon.com/feed';
}
