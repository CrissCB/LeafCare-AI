import 'package:flutter/material.dart';
import 'package:leafcare_ia/app/config/app_theme.dart';

/// Estándar de colores de estado clínico para `user_plants` e `ia_alerts`.
class HealthStatusColors {
  HealthStatusColors._();

  // Códigos HEX canónicos para guardar en PostgreSQL
  static const String healthyHex = '#22C55E'; // Saludable
  static const String attentionHex =
      '#F59E0B'; // Requiere atención / Alerta leve
  static const String criticalHex = '#EF4444'; // Enferma / Crítico
  static const String unevaluatedHex = '#64748B'; // Sin evaluar

  /// Devuelve el HEX canónico según el puntaje de salud (`1..100`).
  static String hexFromHealthScore(int healthScore) {
    if (healthScore >= 75) return healthyHex;
    if (healthScore >= 45) return attentionHex;
    return criticalHex;
  }

  /// Devuelve la descripción/etiqueta estándar asociada al color HEX.
  static String labelFromHex(String? hex) {
    switch (hex?.trim().toUpperCase()) {
      case healthyHex:
        return 'Saludable';
      case attentionHex:
        return 'Requiere atención';
      case criticalHex:
        return 'Enferma / Crítico';
      case unevaluatedHex:
      default:
        return 'Sin evaluar';
    }
  }

  /// Convierte un string hexadecimal (`#RRGGBB` o `#AARRGGBB`) en un [Color].
  static Color fromHex(String? hex, {Color fallback = AppColors.slate}) {
    if (hex == null || hex.trim().isEmpty) return fallback;

    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
