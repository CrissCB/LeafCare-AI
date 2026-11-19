import 'package:flutter/material.dart';
import 'package:leafcare_ia/app/config/app_theme.dart';

class ReminderIconOption {
  const ReminderIconOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color accentColor;
}

/// Catálogo cerrado de íconos permitidos para `care_reminders.icon_name`.
class ReminderIcons {
  ReminderIcons._();

  static const String defaultKey = 'water';

  static const List<ReminderIconOption> options = [
    ReminderIconOption(
      key: 'water',
      label: 'Riego',
      icon: Icons.water_drop_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
    ReminderIconOption(
      key: 'fertilizer',
      label: 'Fertilización',
      icon: Icons.eco_rounded,
      accentColor: AppColors.primary,
    ),
    ReminderIconOption(
      key: 'prune',
      label: 'Poda',
      icon: Icons.content_cut_rounded,
      accentColor: Color(0xFFEC4899),
    ),
    ReminderIconOption(
      key: 'spray',
      label: 'Pulverizar',
      icon: Icons.air_rounded,
      accentColor: Color(0xFF06B6D4),
    ),
    ReminderIconOption(
      key: 'repot',
      label: 'Trasplante',
      icon: Icons.yard_rounded,
      accentColor: Color(0xFFD97706),
    ),
    ReminderIconOption(
      key: 'sunlight',
      label: 'Luz / Rotar',
      icon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    ReminderIconOption(
      key: 'clean',
      label: 'Limpieza',
      icon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
    ReminderIconOption(
      key: 'checkup',
      label: 'Revisión',
      icon: Icons.checklist_rounded,
      accentColor: AppColors.slate,
    ),
  ];

  static final Map<String, ReminderIconOption> _byKey = {
    for (final option in options) option.key: option,
  };

  /// Resuelve la opción visual a partir de `icon_name`, con respaldo inteligente
  /// por texto de acción (útil para recordatorios generados por la IA).
  static ReminderIconOption resolve(String? rawKey, {String? fallbackAction}) {
    final key = rawKey?.trim() ?? '';
    if (key.isNotEmpty && _byKey.containsKey(key)) {
      return _byKey[key]!;
    }

    final action = fallbackAction?.trim().toLowerCase() ?? '';
    if (action.contains('fertil') || action.contains('abon')) {
      return _byKey['fertilizer']!;
    }
    if (action.contains('pod')) return _byKey['prune']!;
    if (action.contains('pulver') || action.contains('fumig')) {
      return _byKey['spray']!;
    }
    if (action.contains('maceta') || action.contains('trasplant')) {
      return _byKey['repot']!;
    }
    if (action.contains('luz') || action.contains('sol')) {
      return _byKey['sunlight']!;
    }
    if (action.contains('limpi')) return _byKey['clean']!;
    if (action.contains('revis')) return _byKey['checkup']!;

    return _byKey[defaultKey]!;
  }
}
