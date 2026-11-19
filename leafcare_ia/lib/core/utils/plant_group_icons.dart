import 'package:flutter/material.dart';

class PlantGroupIconOption {
  const PlantGroupIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

/// Catálogo cerrado de íconos permitidos para `public.plant_groups.icon_name`.
class PlantGroupIcons {
  PlantGroupIcons._();

  static const String defaultKey = 'eco';

  static const List<PlantGroupIconOption> options = [
    PlantGroupIconOption(key: 'eco', label: 'General', icon: Icons.eco_rounded),
    PlantGroupIconOption(
      key: 'living_room',
      label: 'Sala',
      icon: Icons.chair_rounded,
    ),
    PlantGroupIconOption(
      key: 'garden',
      label: 'Jardín',
      icon: Icons.yard_rounded,
    ),
    PlantGroupIconOption(
      key: 'balcony',
      label: 'Balcón',
      icon: Icons.balcony_rounded,
    ),
    PlantGroupIconOption(
      key: 'terrace',
      label: 'Terraza',
      icon: Icons.deck_rounded,
    ),
    PlantGroupIconOption(
      key: 'bedroom',
      label: 'Habitación',
      icon: Icons.bed_rounded,
    ),
    PlantGroupIconOption(
      key: 'kitchen',
      label: 'Cocina',
      icon: Icons.kitchen_rounded,
    ),
    PlantGroupIconOption(
      key: 'office',
      label: 'Oficina',
      icon: Icons.desk_rounded,
    ),
    PlantGroupIconOption(
      key: 'sun',
      label: 'Exterior / Sol',
      icon: Icons.wb_sunny_rounded,
    ),
    PlantGroupIconOption(
      key: 'shade',
      label: 'Sombra',
      icon: Icons.wb_cloudy_rounded,
    ),
    PlantGroupIconOption(
      key: 'water',
      label: 'Humedad',
      icon: Icons.water_drop_rounded,
    ),
    PlantGroupIconOption(
      key: 'folder',
      label: 'Colección',
      icon: Icons.folder_rounded,
    ),
  ];

  static final Map<String, IconData> _iconMap = {
    for (final option in options) option.key: option.icon,
  };

  /// Resuelve el `IconData` a partir del `icon_name` guardado en Supabase.
  static IconData resolve(String? iconName) {
    if (iconName == null || iconName.trim().isEmpty) {
      return Icons.eco_rounded;
    }
    return _iconMap[iconName.trim()] ?? Icons.eco_rounded;
  }
}
