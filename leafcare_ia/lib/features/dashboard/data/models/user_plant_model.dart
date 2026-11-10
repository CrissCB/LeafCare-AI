import 'package:pocketbase/pocketbase.dart';

/// Representa una planta que pertenece al usuario.
///
/// Se construye a partir de un registro de la colección `user_plants`
/// de PocketBase.
class UserPlantModel {
  const UserPlantModel({
    required this.id,
    required this.customName,
    required this.scientificName,
    required this.commonName,
    required this.imageUrl,
    required this.healthLabel,
    required this.healthColorHex,
  });

  /// Identificador del registro en PocketBase.
  final String id;

  /// Nombre que el usuario le puso a su planta.
  final String customName;

  /// Nombre científico (por ejemplo, Monstera deliciosa).
  final String scientificName;

  /// Nombre común (por ejemplo, Costilla de Adán).
  final String commonName;

  /// Dirección de la foto principal (guardada en S3/R2).
  final String imageUrl;

  /// Etiqueta del estado de salud ("Saludable", "Necesita atención"...).
  final String healthLabel;

  /// Color del estado en formato hexadecimal ("#22C55E").
  final String healthColorHex;

  /// Convierte un registro de PocketBase en un objeto de la aplicación.
  factory UserPlantModel.fromRecord(RecordModel record) {
    final data = record.data;

    return UserPlantModel(
      id: record.id,
      customName: _text(data['custom_name'], 'Mi planta'),
      scientificName: _text(data['scientific_name'], ''),
      commonName: _text(data['common_name'], ''),
      imageUrl: _text(data['primary_image_url'], ''),
      healthLabel: _text(data['health_status_label'], 'Sin evaluar'),
      healthColorHex: _text(data['health_status_color'], '#64748B'),
    );
  }

  /// Devuelve el texto limpio o el valor por defecto si viene vacío.
  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
