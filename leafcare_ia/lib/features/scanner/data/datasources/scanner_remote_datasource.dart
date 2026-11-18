import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import 'package:leafcare_ia/core/constants/api_constants.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/utils/health_status_colors.dart';
import 'package:leafcare_ia/features/scanner/data/datasources/perenual_catalog_service.dart';
import 'package:leafcare_ia/features/scanner/data/models/scanner_models.dart';

class ScannerException implements Exception {
  const ScannerException(this.message, {this.isLowConfidence = false});

  final String message;
  final bool isLowConfidence;

  @override
  String toString() => message;
}

class ScannerRemoteDatasource {
  ScannerRemoteDatasource({
    required this.supabaseClient,
    PerenualCatalogService? perenualService,
    http.Client? httpClient,
  }) : _perenualService = perenualService ?? PerenualCatalogService(),
       _httpClient = httpClient ?? http.Client();

  final AppSupabaseClient supabaseClient;
  final PerenualCatalogService _perenualService;
  final http.Client _httpClient;

  static const String _storageBucket = 'plant-images';
  static const String _lowConfidenceMessage =
      'No logramos identificar la planta con precisión. Te sugerimos tomar la foto con mejor iluminación, enfocar las hojas principales o cargar una imagen clara desde tu Galería.';
  static const String _noInternetMessage =
      'Sin conexión a internet. Se requiere acceso a la red para procesar el diagnóstico por IA.';

  SupabaseClient get _client => supabaseClient.client;

  /// Carga los grupos del usuario desde `public.plant_groups`.
  Future<List<ScanGroupOption>> fetchUserGroups() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const ScannerException('Sesión no iniciada.');

    final rows = await _client
        .from('plant_groups')
        .select('id, name')
        .eq('user_id', user.id)
        .order('name', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => ScanGroupOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Carga las plantas pertenecientes a un grupo (`public.user_plants`).
  Future<List<ScanPlantOption>> fetchPlantsByGroup(String groupId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const ScannerException('Sesión no iniciada.');

    final rows = await _client
        .from('user_plants')
        .select(
          'id, group_id, custom_name, scientific_name, common_name, primary_image_url',
        )
        .eq('user_id', user.id)
        .eq('group_id', groupId)
        .order('custom_name', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => ScanPlantOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Verifica conectividad real antes de consumir APIs externas.
  Future<void> _ensureInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('my-api.plantnet.org')
          .timeout(const Duration(seconds: 4));
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        throw const ScannerException(_noInternetMessage);
      }
    } on SocketException {
      throw const ScannerException(_noInternetMessage);
    } catch (e) {
      if (e is ScannerException) rethrow;
      throw const ScannerException(_noInternetMessage);
    }
  }

  /// Comprime la imagen a máx. 1024px para acelerar el envío y ahorrar tokens.
  Future<List<int>> _compressImage(String imagePath) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      imagePath,
      minWidth: 1024,
      minHeight: 1024,
      quality: 82,
      format: CompressFormat.jpeg,
    );
    if (compressed != null && compressed.isNotEmpty) {
      return compressed;
    }
    return await File(imagePath).readAsBytes();
  }

  /// Pipeline completo de análisis: Pl@ntNet -> Perenual (si ID <= 3000) -> Gemini.
  Future<ScanAnalysisResult> analyzeImage({
    required ScanMode mode,
    required String imagePath,
    required ScanGroupOption group,
    ScanPlantOption? existingPlant,
  }) async {
    await _ensureInternetConnection();

    final compressedBytes = await _compressImage(imagePath);

    // 1. Identificar especie con Pl@ntNet
    final plantNetMatch = await _identifyWithPlantNet(compressedBytes);

    // Umbral obligatorio < 50%: bloquea flujo y ahorra llamadas a Perenual y Gemini
    if (plantNetMatch.confidencePercent < 50.0) {
      throw const ScannerException(
        _lowConfidenceMessage,
        isLowConfidence: true,
      );
    }

    // En Modalidad B priorizamos el nombre científico ya registrado si coincide, o el nuevo detectado
    final scientificName =
        (mode == ScanMode.healthDiagnosis && existingPlant != null)
        ? existingPlant.scientificName
        : plantNetMatch.scientificName;

    final commonName =
        (mode == ScanMode.healthDiagnosis && existingPlant != null)
        ? existingPlant.commonName
        : plantNetMatch.commonName;

    // 2. Consultar Perenual solo si está en el índice local <= 3000 (0 requests si no existe)
    final perenualInfo = await _perenualService
        .fetchSpeciesDetailsByScientificName(scientificName);

    // 3. Diagnóstico fitosanitario y recomendaciones con Gemini
    final aiData = await _diagnoseWithGemini(
      imageBytes: compressedBytes,
      scientificName: scientificName,
      commonName: commonName,
      perenualContext: perenualInfo?.toPromptContext(),
    );

    final rawScore = (aiData['health_score'] as num?)?.toInt() ?? 80;
    final clampedScore = rawScore.clamp(1, 100);
    final canonicalHex = _normalizeHexColor(
      aiData['health_status_color']?.toString(),
      clampedScore,
    );

    return ScanAnalysisResult(
      mode: mode,
      groupId: group.id,
      groupName: group.name,
      localImagePath: imagePath,
      scientificName: scientificName,
      commonName: commonName,
      externalSpeciesId: perenualInfo?.id.toString(),
      speciesOrigin:
          perenualInfo?.origin ??
          (perenualInfo != null ? 'PERENUAL' : 'PLANTNET'),
      aiConfidencePercentage: double.parse(
        plantNetMatch.confidencePercent.toStringAsFixed(1),
      ),
      healthScore: clampedScore,
      healthStatusLabel: HealthStatusColors.labelFromHex(canonicalHex),
      healthStatusColorHex: canonicalHex,
      summaryKeyword: (aiData['summary_keyword'] ?? 'DIAGNOSTICO_GENERAL')
          .toString(),
      healthDiagnosisText:
          (aiData['health_diagnosis_text'] ??
                  'No se detectaron anomalías graves en el follaje.')
              .toString(),
      careInstructionsText:
          (aiData['care_instructions_text'] ??
                  'Mantener en luz indirecta brillante y regar cuando el sustrato superior esté seco.')
              .toString(),
      suggestedActionText:
          (aiData['suggested_action_text'] ??
                  'Continuar con el monitoreo semanal de hojas y humedad.')
              .toString(),
      issueTitle: (aiData['issue_title'] ?? 'Revisión de salud completada')
          .toString(),
      shortDescription:
          (aiData['short_description'] ??
                  'Escaneo analizado por IA para $commonName.')
              .toString(),
      fullSummaryIa:
          (aiData['full_summary_ia'] ?? aiData['health_diagnosis_text'] ?? '')
              .toString(),
      existingPlantId: existingPlant?.id,
    );
  }

  /// Guarda Modalidad A: Sube imagen -> INSERT `user_plants` -> INSERT `plant_scans`.
  Future<void> saveNewPlantRegistration({
    required ScanAnalysisResult result,
    required String customName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const ScannerException('Sesión no iniciada.');

    final imageUrl = await _uploadPlantImage(
      userId: user.id,
      localImagePath: result.localImagePath,
    );

    final cleanCustomName = customName.trim().isEmpty
        ? result.commonName
        : customName.trim();

    // 1. Insertar en `user_plants` y recuperar el `id` generado
    final insertedPlant = await _client
        .from('user_plants')
        .insert({
          'user_id': user.id,
          'group_id': result.groupId,
          'custom_name': cleanCustomName,
          'scientific_name': result.scientificName,
          'common_name': result.commonName,
          'species_origin': result.speciesOrigin,
          'external_species_id': result.externalSpeciesId,
          'primary_image_url': imageUrl,
          'health_status_label': result.healthStatusLabel,
          'health_status_color': result.healthStatusColorHex,
        })
        .select('id')
        .single();

    final plantId = insertedPlant['id'].toString();

    // 2. Insertar en `plant_scans` con `scan_type = 'NEW_REGISTRATION'`
    await _client.from('plant_scans').insert({
      'plant_id': plantId,
      'scan_type': ScanMode.newRegistration.dbValue,
      'scanned_image_url': imageUrl,
      'ai_confidence_percentage': result.aiConfidencePercentage,
      'health_score': result.healthScore,
      'summary_keyword': result.summaryKeyword,
      'health_diagnosis_text': result.healthDiagnosisText,
      'care_instructions_text': result.careInstructionsText,
      'suggested_action_text': result.suggestedActionText,
    });
  }

  /// Guarda Modalidad B: Sube imagen -> UPDATE `user_plants` -> INSERT `plant_scans` -> INSERT `ia_alerts`.
  Future<void> saveHealthDiagnosis({required ScanAnalysisResult result}) async {
    final user = _client.auth.currentUser;
    final plantId = result.existingPlantId;
    if (user == null || plantId == null || plantId.isEmpty) {
      throw const ScannerException('No se encontró la planta a diagnosticar.');
    }

    final imageUrl = await _uploadPlantImage(
      userId: user.id,
      localImagePath: result.localImagePath,
    );

    // 1. Actualizar imagen principal y estado de salud en `user_plants`
    await _client
        .from('user_plants')
        .update({
          'primary_image_url': imageUrl,
          'health_status_label': result.healthStatusLabel,
          'health_status_color': result.healthStatusColorHex,
        })
        .eq('id', plantId);

    // 2. Insertar escaneo en `plant_scans` y recuperar `scan_id`
    final insertedScan = await _client
        .from('plant_scans')
        .insert({
          'plant_id': plantId,
          'scan_type': ScanMode.healthDiagnosis.dbValue,
          'scanned_image_url': imageUrl,
          'ai_confidence_percentage': result.aiConfidencePercentage,
          'health_score': result.healthScore,
          'summary_keyword': result.summaryKeyword,
          'health_diagnosis_text': result.healthDiagnosisText,
          'care_instructions_text': result.careInstructionsText,
          'suggested_action_text': result.suggestedActionText,
        })
        .select('id')
        .single();

    final scanId = insertedScan['id'].toString();

    // 3. Insertar alerta en `ia_alerts`
    await _client.from('ia_alerts').insert({
      'user_id': user.id,
      'plant_id': plantId,
      'scan_id': scanId,
      'issue_title': result.issueTitle,
      'short_description': result.shortDescription,
      'full_summary_ia': result.fullSummaryIa,
      'status_color': result.healthStatusColorHex,
      'is_read': false,
    });
  }

  Future<String> _uploadPlantImage({
    required String userId,
    required String localImagePath,
  }) async {
    final bytes = await _compressImage(localImagePath);
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage
        .from(_storageBucket)
        .uploadBinary(
          fileName,
          bytes as dynamic,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage.from(_storageBucket).getPublicUrl(fileName);
  }

  Future<_PlantNetMatch> _identifyWithPlantNet(List<int> imageBytes) async {
    if (ApiConstants.plantNetApiKey.isEmpty) {
      throw const ScannerException('Falta configurar PLANTNET_API_KEY en .env');
    }

    final uri =
        Uri.parse(
          '${ApiConstants.plantNetBaseUrl}${ApiConstants.plantNetIdentifyEndpoint}',
        ).replace(
          queryParameters: {
            'lang': ApiConstants.plantNetDefaultLang,
            'api-key': ApiConstants.plantNetApiKey,
          },
        );

    final request = http.MultipartRequest('POST', uri)
      ..fields['organs'] = 'leaf'
      ..files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytes,
          filename: 'scan.jpg',
        ),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 404) {
      throw const ScannerException(
        _lowConfidenceMessage,
        isLowConfidence: true,
      );
    }

    if (streamed.statusCode != 200) {
      throw const ScannerException(
        'No se pudo procesar la imagen en el servicio botánico.',
      );
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final results = (decoded['results'] as List<dynamic>?) ?? [];
    if (results.isEmpty) {
      throw const ScannerException(
        _lowConfidenceMessage,
        isLowConfidence: true,
      );
    }

    final best = results.first as Map<String, dynamic>;
    final score = (best['score'] as num?)?.toDouble() ?? 0.0;
    final species = (best['species'] as Map<String, dynamic>?) ?? {};
    final scientificName =
        (species['scientificNameWithoutAuthor'] ?? 'Especie desconocida')
            .toString();
    final commonNames = (species['commonNames'] as List<dynamic>?) ?? [];
    final commonName = commonNames.isNotEmpty
        ? commonNames.first.toString()
        : scientificName;

    return _PlantNetMatch(
      scientificName: scientificName,
      commonName: commonName,
      confidencePercent: score * 100.0,
    );
  }

  Future<Map<String, dynamic>> _diagnoseWithGemini({
    required List<int> imageBytes,
    required String scientificName,
    required String commonName,
    String? perenualContext,
  }) async {
    if (ApiConstants.geminiApiKey.isEmpty) {
      throw const ScannerException('Falta configurar GEMINI_API_KEY en .env');
    }

    final prompt =
        '''
Eres un especialista en botánica y diagnóstico fitosanitario para la app LeafCare AI.
Analiza la foto de la planta: $commonName ($scientificName).
${perenualContext != null ? 'Ficha botánica conocida: $perenualContext.' : ''}

Evalúa signos visuales de salud o estrés ambiental (falta de agua, exceso de riego, exceso de sol/quemadura, falta de luz, plagas u hongos).
Usa estrictamente uno de estos códigos hexadecimales para "health_status_color":
- "${HealthStatusColors.healthyHex}" si la planta está saludable (health_score entre 75 y 100)
- "${HealthStatusColors.attentionHex}" si requiere atención por estrés leve o moderado (health_score entre 45 y 74)
- "${HealthStatusColors.criticalHex}" si está enferma o en estado crítico con daño severo, pudrición o plaga activa (health_score entre 1 y 44)

Responde ÚNICAMENTE con un JSON válido con esta estructura exacta:
{
  "health_score": 85,
  "health_status_color": "${HealthStatusColors.healthyHex}",
  "summary_keyword": "SALUDABLE",
  "health_diagnosis_text": "Descripción detallada del estado visible de las hojas, tallos y coloración.",
  "care_instructions_text": "Instrucciones claras de riego, iluminación y sustrato ideales para esta especie.",
  "suggested_action_text": "Pasos concretos que el usuario debe realizar hoy y en los próximos días.",
  "issue_title": "Título corto para la alerta (ej. Planta saludable / Posible exceso de riego)",
  "short_description": "Resumen breve de 1 oración para mostrar en la tarjeta de alerta.",
  "full_summary_ia": "Informe completo consolidado con diagnóstico, causas probables y plan de recuperación."
}
''';

    final response = await _httpClient
        .post(
          ApiConstants.geminiGenerateContentUri(),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Encode(imageBytes),
                    },
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.2,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw const ScannerException(
        'No se pudo completar el análisis de salud por IA. Intenta de nuevo.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
        ?.toString();

    if (rawText == null || rawText.isEmpty) {
      throw const ScannerException('La IA devolvió una respuesta vacía.');
    }

    return jsonDecode(rawText) as Map<String, dynamic>;
  }

  /// Garantiza que `health_status_color` coincida con los HEX canónicos de [HealthStatusColors].
  String _normalizeHexColor(String? raw, int healthScore) {
    final clean = (raw ?? '').trim().toUpperCase();
    const validColors = {
      HealthStatusColors.healthyHex,
      HealthStatusColors.attentionHex,
      HealthStatusColors.criticalHex,
      HealthStatusColors.unevaluatedHex,
    };

    if (validColors.contains(clean)) {
      return clean;
    }
    return HealthStatusColors.hexFromHealthScore(healthScore);
  }
}

class _PlantNetMatch {
  const _PlantNetMatch({
    required this.scientificName,
    required this.commonName,
    required this.confidencePercent,
  });

  final String scientificName;
  final String commonName;
  final double confidencePercent;
}
