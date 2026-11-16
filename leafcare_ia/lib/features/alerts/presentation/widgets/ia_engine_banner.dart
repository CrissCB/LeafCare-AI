import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';

/// Banner superior de estado del motor de monitoreo IA.
class IaEngineBanner extends StatelessWidget {
  const IaEngineBanner({super.key, required this.monitoredPlantsCount});

  final int monitoredPlantsCount;

  @override
  Widget build(BuildContext context) {
    final subtitleText = monitoredPlantsCount == 1
        ? 'Análisis continuo de 1 planta monitoreada'
        : 'Análisis continuo de $monitoredPlantsCount plantas monitoreadas';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono izquierdo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neon.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: AppColors.neon,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Título y conteo de plantas monitoreadas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motor de IA activo',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Etiqueta con borde LIVE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.neon.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.neon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
