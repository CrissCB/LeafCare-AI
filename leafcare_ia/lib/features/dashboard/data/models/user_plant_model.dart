/// Representa una planta que pertenece al usuario.
///
/// Se construye a partir de un registro de la tabla `user_plants` en Supabase.
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

  /// Identificador del registro en Supabase/PostgreSQL (UUID).
  final String id;

  /// Nombre que el usuario le puso a su planta.
  final String customName;

  /// Nombre científico (por ejemplo, Monstera deliciosa).
  final String scientificName;

  /// Nombre común (por ejemplo, Costilla de Adán).
  final String commonName;

  /// Dirección de la foto principal (guardada en Supabase Storage / S3).
  final String imageUrl;

  /// Etiqueta del estado de salud ("Saludable", "Necesita atención"...).
  final String healthLabel;

  /// Color del estado en formato hexadecimal ("#22C55E").
  final String healthColorHex;

  /// Convierte un mapa JSON de Supabase/PostgreSQL en un objeto de la aplicación.
  factory UserPlantModel.fromJson(Map<String, dynamic> json) {
    return UserPlantModel(
      id: json['id']?.toString() ?? '',
      customName: _text(json['custom_name'], 'Mi planta'),
      scientificName: _text(json['scientific_name'], ''),
      commonName: _text(json['common_name'], ''),
      imageUrl: _text(json['primary_image_url'], ''),
      healthLabel: _text(json['health_status_label'], 'Sin evaluar'),
      healthColorHex: _text(json['health_status_color'], '#64748B'),
    );
  }

  /// Convierte la instancia a un mapa JSON para inserciones o actualizaciones.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'custom_name': customName,
      'scientific_name': scientificName,
      'common_name': commonName,
      'primary_image_url': imageUrl,
      'health_status_label': healthLabel,
      'health_status_color': healthColorHex,
    };
  }

  /// Devuelve el texto limpio o el valor por defecto si viene vacío.
  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
