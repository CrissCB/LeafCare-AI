import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:leafcare_ia/core/constants/api_constants.dart';

class PerenualSpeciesInfo {
  const PerenualSpeciesInfo({
    required this.id,
    required this.watering,
    required this.sunlight,
    this.careLevel,
    this.origin,
    this.description,
    this.poisonousToPets = false,
  });

  final int id;
  final String watering;
  final String sunlight;
  final String? careLevel;
  final String? origin;
  final String? description;
  final bool poisonousToPets;

  String toPromptContext() {
    final parts = <String>[
      'Riego recomendado: $watering',
      'Exposición solar: $sunlight',
      if (careLevel != null && careLevel!.isNotEmpty)
        'Nivel de cuidado: $careLevel',
      if (origin != null && origin!.isNotEmpty) 'Origen: $origin',
      if (poisonousToPets) 'Advertencia: tóxica para mascotas',
    ];
    return parts.join(' | ');
  }
}

class PerenualCatalogService {
  PerenualCatalogService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  Map<String, int>? _scientificNameToId;

  /// Carga `assets/data/perenual_index.json` una sola vez en memoria.
  Future<void> _ensureIndexLoaded() async {
    if (_scientificNameToId != null) return;

    try {
      final rawJson = await rootBundle.loadString(
        ApiConstants.perenualIndexAssetPath,
      );
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final rawMap =
          (decoded['species_by_scientific_name'] as Map<String, dynamic>?) ??
          {};

      final parsed = <String, int>{};
      rawMap.forEach((key, value) {
        final id = (value as num?)?.toInt();
        if (id != null && id <= ApiConstants.perenualMaxFreeId) {
          parsed[key.trim().toLowerCase()] = id;
        }
      });
      _scientificNameToId = parsed;
    } catch (_) {
      _scientificNameToId = {};
    }
  }

  /// Devuelve el ID de Perenual (<= 3000) si existe en el índice local, o `null` con 0 requests.
  Future<int?> findFreeSpeciesId(String scientificName) async {
    await _ensureIndexLoaded();
    final normalized = scientificName.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return _scientificNameToId?[normalized];
  }

  /// Consulta la ficha detallada solo si el ID está dentro del rango gratuito (<= 3000).
  Future<PerenualSpeciesInfo?> fetchSpeciesDetailsByScientificName(
    String scientificName,
  ) async {
    final id = await findFreeSpeciesId(scientificName);
    if (id == null || ApiConstants.perenualApiKey.isEmpty) return null;

    final uri = Uri.parse(
      '${ApiConstants.perenualBaseUrl}${ApiConstants.perenualSpeciesDetailsEndpoint}/$id',
    ).replace(queryParameters: {'key': ApiConstants.perenualApiKey});

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final watering = (data['watering'] ?? '').toString();
      if (watering.toLowerCase().contains('upgrade')) return null;

      final sunlightList = (data['sunlight'] as List<dynamic>?) ?? [];
      final originList = (data['origin'] as List<dynamic>?) ?? [];

      return PerenualSpeciesInfo(
        id: id,
        watering: watering.isNotEmpty ? watering : 'Moderado',
        sunlight: sunlightList.isNotEmpty
            ? sunlightList.map((e) => e.toString()).join(', ')
            : 'Luz indirecta brillante',
        careLevel: data['care_level']?.toString(),
        origin: originList.isNotEmpty
            ? originList.map((e) => e.toString()).join(', ')
            : null,
        description: data['description']?.toString(),
        poisonousToPets: (data['poisonous_to_pets'] as num?)?.toInt() == 1,
      );
    } catch (_) {
      return null;
    }
  }
}
