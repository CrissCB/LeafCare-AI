import 'package:flutter/material.dart';
import 'package:leafcare_ia/core/utils/plant_group_icons.dart';

class PlantGroupModel {
  const PlantGroupModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconName,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String iconName;
  final DateTime? createdAt;

  IconData get icon => PlantGroupIcons.resolve(iconName);

  PlantGroupModel copyWith({String? name, String? iconName}) {
    return PlantGroupModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
    );
  }

  factory PlantGroupModel.fromJson(Map<String, dynamic> json) {
    return PlantGroupModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Sin nombre',
      iconName: json['icon_name'] as String? ?? PlantGroupIcons.defaultKey,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'name': name.trim(), 'icon_name': iconName};
  }
}
