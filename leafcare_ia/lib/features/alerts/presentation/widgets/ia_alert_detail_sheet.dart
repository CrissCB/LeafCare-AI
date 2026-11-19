import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/alerts/data/datasources/alerts_datasource.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_model.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_scan_detail_model.dart';
import 'package:leafcare_ia/features/alerts/data/repositories/alerts_repository.dart';

/// Panel inferior con el diagnóstico completo extraído de `plant_scans` y `user_plants`.
class IaAlertDetailSheet extends StatefulWidget {
  const IaAlertDetailSheet({super.key, required this.alert});

  final IaAlertModel alert;

  static Future<void> show(
    BuildContext context, {
    required IaAlertModel alert,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => IaAlertDetailSheet(alert: alert),
    );
  }

  @override
  State<IaAlertDetailSheet> createState() => _IaAlertDetailSheetState();
}

class _IaAlertDetailSheetState extends State<IaAlertDetailSheet> {
  late final AlertsRepository _repository;
  late Future<IaAlertScanDetailModel> _detailFuture;

  /// Índice del acordeón abierto (0 = Diagnóstico detallado abierto por defecto).
  int? _expandedIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = AlertsRepository(
      datasource: AlertsDatasource(supabaseClient: const AppSupabaseClient()),
    );
    _detailFuture = _repository.fetchAlertScanDetail(widget.alert);
  }

  void _retry() {
    setState(() {
      _detailFuture = _repository.fetchAlertScanDetail(widget.alert);
    });
  }

  String _formattedBadgeText() {
    final raw = widget.alert.shortDescription.trim();
    if (raw.isEmpty) return 'IA - Diagnóstico';
    if (raw.toLowerCase().startsWith('ia')) return raw;
    return 'IA - $raw';
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.84;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<IaAlertScanDetailModel>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 300,
                      child: LoadingIndicator(),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 38,
                            color: AppColors.slateLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se pudo cargar el diagnóstico del escaneo',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.anthracite,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reintentar'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final detail = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Recuadro superior con fondo translúcido de status_color
                        _AlertStatusHeaderCard(
                          statusColor: widget.alert.statusColor,
                          badgeText: _formattedBadgeText(),
                          title: widget.alert.issueTitle,
                        ),
                        const SizedBox(height: 14),

                        // 2. Recuadro de confianza del modelo de IA
                        if (detail.confidencePercent != null) ...[
                          _AiConfidenceCard(
                            percentage: detail.confidencePercent!,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3. Imagen del escaneo + custom_name + scientific_name
                        _ScannedPlantRow(
                          imageUrl: detail.scanImageUrl,
                          customName: detail.customName,
                          scientificName: detail.scientificName,
                        ),
                        const SizedBox(height: 18),

                        // 4. Opciones desplegables de plant_scans
                        _DiagnosticAccordionTile(
                          icon: Icons.biotech_outlined,
                          iconColor: AppColors.primary,
                          title: 'Diagnóstico detallado de salud',
                          content: detail.healthDiagnosisText,
                          isExpanded: _expandedIndex == 0,
                          onTap: () => setState(() {
                            _expandedIndex = _expandedIndex == 0 ? null : 0;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _DiagnosticAccordionTile(
                          icon: Icons.assignment_outlined,
                          iconColor: const Color(0xFFD97706),
                          title: 'Instrucciones de cuidado',
                          content: detail.careInstructionsText,
                          isExpanded: _expandedIndex == 1,
                          onTap: () => setState(() {
                            _expandedIndex = _expandedIndex == 1 ? null : 1;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _DiagnosticAccordionTile(
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFFEA580C),
                          title: 'Acción sugerida',
                          content: detail.suggestedActionText,
                          isExpanded: _expandedIndex == 2,
                          onTap: () => setState(() {
                            _expandedIndex = _expandedIndex == 2 ? null : 2;
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1. Recuadro superior redondeado con tinte suave de `status_color`, pill `IA - ...` y título.
class _AlertStatusHeaderCard extends StatelessWidget {
  const _AlertStatusHeaderCard({
    required this.statusColor,
    required this.badgeText,
    required this.title,
  });

  final Color statusColor;
  final String badgeText;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Recuadro de confianza del modelo con barra degradada verde oscuro -> verde brillante.
class _AiConfidenceCard extends StatelessWidget {
  const _AiConfidenceCard({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final factor = (percentage.clamp(0, 100)) / 100.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Columna izquierda: título + barra + escala 0%..100%
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confianza del modelo de IA',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: AppColors.border,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: factor,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                              AppColors.neon,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final mark in const [
                      '0%',
                      '25%',
                      '50%',
                      '75%',
                      '100%',
                    ])
                      Text(
                        mark,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slateLight,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Columna derecha: porcentaje grande + "coincidencia"
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$percentage',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    '%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'coincidencia',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3. Miniatura del escaneo junto al `custom_name` y `scientific_name` de `user_plants`.
class _ScannedPlantRow extends StatelessWidget {
  const _ScannedPlantRow({
    this.imageUrl,
    required this.customName,
    this.scientificName,
  });

  final String? imageUrl;
  final String customName;
  final String? scientificName;

  @override
  Widget build(BuildContext context) {
    final img = imageUrl?.trim() ?? '';

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: img.isNotEmpty
              ? Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                )
              : const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.anthracite,
                ),
              ),
              if (scientificName != null && scientificName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  scientificName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 4. Tarjeta desplegable para los textos clínicos del escaneo.
class _DiagnosticAccordionTile extends StatelessWidget {
  const _DiagnosticAccordionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isExpanded
            ? AppColors.mint.withValues(alpha: 0.55)
            : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? AppColors.primary : AppColors.border,
          width: isExpanded ? 1.3 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.anthracite,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.slate,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.anthracite,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
