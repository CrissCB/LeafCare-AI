import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';

/// Tarjeta de una planta para la lista horizontal de la pantalla principal.
class PlantCard extends StatelessWidget {
  const PlantCard({super.key, required this.plant, this.onTap});

  final UserPlantModel plant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _colorFromHex(plant.healthColorHex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto de la planta (o ícono si no tiene)
            SizedBox(
              height: 104,
              width: double.infinity,
              child: plant.imageUrl.isNotEmpty
                  ? Image.network(
                      plant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _PlantPlaceholder(),
                    )
                  : const _PlantPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.customName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.anthracite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plant.scientificName.isNotEmpty
                        ? plant.scientificName
                        : plant.commonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppColors.slateLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Etiqueta con el estado de salud
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            plant.healthLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Convierte un color hexadecimal ("#22C55E") en un Color de Flutter.
  Color _colorFromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? AppColors.slate : Color(parsed);
  }
}

/// Fondo verde con una hojita, para cuando la planta no tiene foto.
class _PlantPlaceholder extends StatelessWidget {
  const _PlantPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mint,
      child: const Center(
        child: Icon(Icons.eco_rounded, size: 36, color: AppColors.primary),
      ),
    );
  }
}
