import 'package:flutter/material.dart';
import 'package:leafcare_ia/core/utils/health_status_colors.dart';

class PlantHealthStatusOption {
  const PlantHealthStatusOption({
    required this.key,
    required this.label,
    required this.hexColor,
    required this.icon,
    required this.severityRank,
  });

  final String key;
  final String label;
  final String hexColor;
  final IconData icon;

  /// Prioridad clínica para ordenamiento: 0 = más urgente, 3 = saludable.
  final int severityRank;

  Color get color => HealthStatusColors.fromHex(hexColor);
}

/// Catálogo cerrado y fuente única de verdad para `health_status_label` y `health_status_color`.
class PlantHealthStatus {
  PlantHealthStatus._();

  // Etiquetas canónicas para guardar en PostgreSQL (`user_plants.health_status_label`)
  static const String criticalLabel = 'Enferma';
  static const String attentionLabel = 'Requiere atención';
  static const String unevaluatedLabel = 'Sin evaluar';
  static const String healthyLabel = 'Saludable';

  static const PlantHealthStatusOption critical = PlantHealthStatusOption(
    key: 'critical',
    label: criticalLabel,
    hexColor: HealthStatusColors.criticalHex, // #EF4444
    icon: Icons.error_rounded,
    severityRank: 0,
  );

  static const PlantHealthStatusOption attention = PlantHealthStatusOption(
    key: 'attention',
    label: attentionLabel,
    hexColor: HealthStatusColors.attentionHex, // #F59E0B
    icon: Icons.warning_amber_rounded,
    severityRank: 1,
  );

  static const PlantHealthStatusOption unevaluated = PlantHealthStatusOption(
    key: 'unevaluated',
    label: unevaluatedLabel,
    hexColor: HealthStatusColors.unevaluatedHex, // #64748B
    icon: Icons.help_outline_rounded,
    severityRank: 2,
  );

  static const PlantHealthStatusOption healthy = PlantHealthStatusOption(
    key: 'healthy',
    label: healthyLabel,
    hexColor: HealthStatusColors.healthyHex, // #22C55E
    icon: Icons.check_circle_rounded,
    severityRank: 3,
  );

  /// Lista ordenada de mayor a menor prioridad clínica.
  static const List<PlantHealthStatusOption> options = [
    critical,
    attention,
    unevaluated,
    healthy,
  ];

  /// Normaliza cualquier etiqueta proveniente de la BD o de la IA a una opción canónica.
  static PlantHealthStatusOption resolve(String? rawLabel) {
    final text = rawLabel?.trim().toLowerCase() ?? '';
    if (text.isEmpty || text.contains('sin evaluar') || text.contains('pend')) {
      return unevaluated;
    }
    if (text.contains('enferm') ||
        text.contains('crític') ||
        text.contains('critic') ||
        text.contains('grave') ||
        text.contains('urgente')) {
      return critical;
    }
    if (text.contains('aten') ||
        text.contains('alert') ||
        text.contains('riesgo') ||
        text.contains('precau') ||
        text.contains('leve')) {
      return attention;
    }
    if (text.contains('salud') ||
        text.contains('sana') ||
        text.contains('óptim')) {
      return healthy;
    }
    return unevaluated;
  }

  /// Devuelve el peso de urgencia para ordenar listas de plantas.
  static int severityRank(String? rawLabel) => resolve(rawLabel).severityRank;
}
