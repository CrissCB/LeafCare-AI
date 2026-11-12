/// Representa una alerta generada por la inteligencia artificial.
///
/// Se construye a partir de una fila de la tabla `ia_alerts` en Supabase.
class AlertModel {
  const AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.summary,
    required this.statusColorHex,
    required this.isRead,
    required this.created,
  });

  final String id;
  final String title;
  final String description;
  final String summary;
  final String statusColorHex;
  final bool isRead;
  final DateTime created;

  /// Convierte el mapa JSON de Supabase/PostgreSQL en un objeto de la aplicación.
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final createdRaw =
        json['created_at']?.toString() ?? json['created']?.toString() ?? '';

    return AlertModel(
      id: json['id']?.toString() ?? '',
      title: _text(json['issue_title'], 'Alerta de tu planta'),
      description: _text(json['short_description'], ''),
      summary: _text(json['full_summary_ia'], ''),
      statusColorHex: _text(json['status_color'], '#DC2626'),
      isRead: json['is_read'] == true,
      created: DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now(),
    );
  }

  /// Convierte la instancia a JSON para operaciones en base de datos.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_title': title,
      'short_description': description,
      'full_summary_ia': summary,
      'status_color': statusColorHex,
      'is_read': isRead,
      'created_at': created.toIso8601String(),
    };
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
