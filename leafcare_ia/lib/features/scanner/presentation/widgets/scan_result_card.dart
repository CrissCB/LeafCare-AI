import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/utils/health_status_colors.dart';
import 'package:leafcare_ia/features/scanner/data/models/scanner_models.dart';

class ScanResultCard extends StatefulWidget {
  const ScanResultCard({
    super.key,
    required this.result,
    required this.saving,
    this.onSaveNewPlant,
    required this.onCancelOrDone,
  });

  final ScanAnalysisResult result;
  final bool saving;
  final ValueChanged<String>? onSaveNewPlant;
  final VoidCallback onCancelOrDone;

  @override
  State<ScanResultCard> createState() => _ScanResultCardState();
}

class _ScanResultCardState extends State<ScanResultCard> {
  late final TextEditingController _customNameController;

  @override
  void initState() {
    super.initState();
    _customNameController = TextEditingController(
      text: widget.result.commonName,
    );
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final statusColor = HealthStatusColors.fromHex(
      r.healthStatusColorHex,
      fallback: AppColors.primary,
    );
    final confidenceRatio = (r.aiConfidencePercentage / 100).clamp(0.0, 1.0);
    final isNewRegistration = r.mode == ScanMode.newRegistration;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen capturada con badge de estado
          Stack(
            children: [
              Image.file(
                File(r.localImagePath),
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    r.healthStatusLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera exacta solicitada
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IA - Diagnóstico | Estado: Especie Identificada | ${r.scientificName}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Barra de progreso de confianza
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Confianza del modelo de IA: ${r.aiConfidencePercentage.toStringAsFixed(1)}% coincidencia',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.anthracite,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: confidenceRatio,
                    minHeight: 8,
                    backgroundColor: AppColors.mint,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de nombre personalizado para `user_plants.custom_name` (solo Modalidad A)
                if (isNewRegistration) ...[
                  Text(
                    'Nombre para tu planta',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.anthracite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _customNameController,
                    decoration: InputDecoration(
                      hintText: 'Ej. Monstera de la sala',
                      prefixIcon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 3 Menús desplegables
                _ExpandableInfoTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Diagnóstico detallado de salud',
                  content: r.healthDiagnosisText,
                  initiallyExpanded: true,
                ),
                const SizedBox(height: 8),
                _ExpandableInfoTile(
                  icon: Icons.water_drop_outlined,
                  title: 'Instrucciones de cuidado',
                  content: r.careInstructionsText,
                ),
                const SizedBox(height: 8),
                _ExpandableInfoTile(
                  icon: Icons.tips_and_updates_outlined,
                  title: 'Acción sugerida',
                  content: r.suggestedActionText,
                ),
                const SizedBox(height: 18),

                // Botones de acción
                if (isNewRegistration)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.saving
                              ? null
                              : widget.onCancelOrDone,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.slate,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: widget.saving
                              ? null
                              : () => widget.onSaveNewPlant?.call(
                                  _customNameController.text,
                                ),
                          icon: widget.saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 19),
                          label: Text(
                            widget.saving ? 'Guardando...' : 'Guardar',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onCancelOrDone,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Realizar otro escaneo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableInfoTile extends StatelessWidget {
  const _ExpandableInfoTile({
    required this.icon,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String content;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(icon, color: AppColors.primary, size: 20),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.anthracite,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.slate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
