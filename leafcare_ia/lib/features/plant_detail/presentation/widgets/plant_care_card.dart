import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/plant_detail_model.dart';

class PlantCareCard extends StatelessWidget {
  const PlantCareCard({super.key, required this.plant});

  final PlantDetailModel plant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '2. Cuidado Requerido',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.anthracite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cuadrícula 2x2
          Row(
            children: [
              Expanded(
                child: _PastelMetricTile(
                  icon: Icons.water_drop_rounded,
                  label: 'RIEGO',
                  value: 'Cada ${plant.wateringFrequencyDays.toInt()} días',
                  accentColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PastelMetricTile(
                  icon: Icons.wb_sunny_rounded,
                  label: 'LUZ',
                  value: plant.sunlightRequirement,
                  accentColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFEF3C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PastelMetricTile(
                  icon: Icons.thermostat_rounded,
                  label: 'TEMPERATURA',
                  value:
                      '${plant.minTemp.toInt()} – ${plant.maxTemp.toInt()} °C',
                  accentColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFEE2E2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PastelMetricTile(
                  icon: Icons.air_rounded,
                  label: 'HUMEDAD',
                  value: '${plant.humidity.toInt()} %',
                  accentColor: const Color(0xFF0891B2),
                  bgColor: const Color(0xFFECFEFF),
                  borderColor: const Color(0xFFCFFAFE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _TextCareBox(
            label: 'SUSTRATO RECOMENDADO',
            value: plant.soilCharacteristics,
          ),
          const SizedBox(height: 10),
          _TextCareBox(
            label: 'FERTILIZACIÓN',
            value: plant.fertilizerCharacteristics,
          ),
        ],
      ),
    );
  }
}

class _PastelMetricTile extends StatelessWidget {
  const _PastelMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.isNotEmpty ? value : '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.anthracite,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCareBox extends StatelessWidget {
  const _TextCareBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : '—',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.anthracite,
            ),
          ),
        ],
      ),
    );
  }
}
