/// Resultado de identificar una planta con la API de Pl@ntNet.
class PlantIdentificationModel {
  const PlantIdentificationModel({
    required this.scientificName,
    required this.commonName,
    required this.family,
    required this.score,
    required this.imageUrl,
  });

  /// Nombre científico (por ejemplo, Monstera deliciosa).
  final String scientificName;

  /// Nombre común en español (por ejemplo, Costilla de Adán).
  final String commonName;

  /// Familia botánica (por ejemplo, Araceae).
  final String family;

  /// Qué tan segura está la IA, de 0 a 1.
  final double score;

  /// Foto de referencia que devuelve Pl@ntNet.
  final String imageUrl;

  /// El porcentaje de seguridad, redondeado.
  int get scorePercent => (score * 100).round();

  /// Convierte la respuesta de Pl@ntNet en un objeto de la aplicación.
  factory PlantIdentificationModel.fromJson(Map<String, dynamic> json) {
    final species = (json['species'] as Map<String, dynamic>?) ?? const {};
    final family = (species['family'] as Map<String, dynamic>?) ?? const {};
    final commonNames = (species['commonNames'] as List?) ?? const [];
    final images = (json['images'] as List?) ?? const [];

    // Intentamos sacar la foto de referencia del primer resultado.
    var imageUrl = '';
    if (images.isNotEmpty) {
      final firstImage = images.first;
      if (firstImage is Map) {
        final url = firstImage['url'];
        if (url is Map) {
          imageUrl = (url['m'] ?? url['o'] ?? url['s'] ?? '').toString();
        }
      }
    }

    return PlantIdentificationModel(
      scientificName:
          (species['scientificNameWithoutAuthor'] ?? 'Especie desconocida')
              .toString(),
      commonName: commonNames.isEmpty ? '' : commonNames.first.toString(),
      family: (family['scientificNameWithoutAuthor'] ?? '').toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      imageUrl: imageUrl,
    );
  }
}

/// Error controlado del servicio de identificación.
class PlantNetException implements Exception {
  const PlantNetException(this.message);

  final String message;

  @override
  String toString() => message;
}
