import 'package:pocketbase/pocketbase.dart';

/// Un análisis hecho por la inteligencia artificial a una planta.
///
/// Se construye a partir de un registro de la colección `plant_scans`.
class PlantScanModel {
  const PlantScanModel({
    required this.id,
    required this.scanType,
    required this.healthScore,
    required this.confidence,
    required this.summaryKeyword,
    required this.diagnosis,
    required this.careInstructions,
    required this.suggestedAction,
    required this.created,
  });

  final String id;
  final String scanType;
  final double healthScore;
  final double confidence;
  final String summaryKeyword;
  final String diagnosis;
  final String careInstructions;
  final String suggestedAction;
  final DateTime created;

  /// Texto amigable del tipo de análisis.
  String get typeLabel {
    switch (scanType) {
      case 'NEW_REGISTRATION':
        return 'Registro';
      case 'HEALTH_DIAGNOSIS':
        return 'Diagnóstico';
      default:
        return 'Análisis';
    }
  }

  factory PlantScanModel.fromRecord(RecordModel record) {
    final data = record.data;

    return PlantScanModel(
      id: record.id,
      scanType: data['scan_type']?.toString() ?? '',
      healthScore: _number(data['health_score']),
      confidence: _number(data['ai_confidence_percentage']),
      summaryKeyword: _text(data['summary_keyword'], ''),
      diagnosis: _text(data['health_diagnosis_text'], ''),
      careInstructions: _text(data['care_instructions_text'], ''),
      suggestedAction: _text(data['suggested_action_text'], ''),
      created: DateTime.tryParse(record.get<String>('created'))?.toLocal() ??
          DateTime.now(),
    );
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
