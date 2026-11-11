import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/plant_detail_model.dart';

class PlantDetailHero extends StatelessWidget {
  const PlantDetailHero({
    super.key,
    required this.plant,
    required this.onMoreOptions,
  });

  final PlantDetailModel plant;
  final VoidCallback onMoreOptions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          plant.primaryImageUrl.isNotEmpty
              ? Image.network(
                  plant.primaryImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _FallbackEco(),
                )
              : const _FallbackEco(),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xCC0A2E1D),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Botones de navegación (Top)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CircleBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => context.pop(),
                  ),
                  _CircleBtn(
                    icon: Icons.more_vert_rounded,
                    onTap: onMoreOptions,
                  ),
                ],
              ),
            ),
          ),

          // Textos y Badges (Bottom)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.customName,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.15,
                  ),
                ),
                if (plant.scientificName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    plant.scientificName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Badge Grupo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.neon, width: 1.2),
                      ),
                      child: Text(
                        plant.groupName,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge Escaneos
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${plant.scanHistory.length} escaneos',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _FallbackEco extends StatelessWidget {
  const _FallbackEco();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mint,
      child: const Center(
        child: Icon(Icons.eco_rounded, size: 64, color: AppColors.primary),
      ),
    );
  }
}
