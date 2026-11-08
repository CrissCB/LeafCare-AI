import 'package:pocketbase/pocketbase.dart';

/// Representa una alerta generada por la inteligencia artificial.
///
/// Se construye a partir de un registro de la colección `ia_alerts`.
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

  /// Convierte un registro de PocketBase en un objeto de la aplicación.
  factory AlertModel.fromRecord(RecordModel record) {
    final data = record.data;

    return AlertModel(
      id: record.id,
      title: _text(data['issue_title'], 'Alerta de tu planta'),
      description: _text(data['short_description'], ''),
      summary: _text(data['full_summary_ia'], ''),
      statusColorHex: _text(data['status_color'], '#DC2626'),
      isRead: data['is_read'] == true,
      created:
          DateTime.tryParse(record.get<String>('created'))?.toLocal() ??
          DateTime.now(),
    );
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
