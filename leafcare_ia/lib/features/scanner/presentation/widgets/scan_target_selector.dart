import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/scanner/data/models/scanner_models.dart';

class ScanTargetSelector extends StatelessWidget {
  const ScanTargetSelector({
    super.key,
    required this.mode,
    required this.groups,
    required this.selectedGroup,
    required this.onGroupChanged,
    required this.groupPlants,
    required this.selectedPlant,
    required this.loadingPlants,
    required this.onPlantChanged,
  });

  final ScanMode mode;
  final List<ScanGroupOption> groups;
  final ScanGroupOption? selectedGroup;
  final ValueChanged<ScanGroupOption> onGroupChanged;

  final List<ScanPlantOption> groupPlants;
  final ScanPlantOption? selectedPlant;
  final bool loadingPlants;
  final ValueChanged<ScanPlantOption> onPlantChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de Grupo (obligatorio)
          Text(
            '1. Selecciona el grupo',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Aún no tienes grupos creados. Crea un grupo en tu jardín antes de escanear una planta.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF92400E),
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedGroup?.id,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Elige un grupo (obligatorio)',
                prefixIcon: const Icon(
                  Icons.folder_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
              items: groups
                  .map(
                    (g) => DropdownMenuItem<String>(
                      value: g.id,
                      child: Text(
                        g.name,
                        style: GoogleFonts.inter(fontSize: 13.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final found = groups.firstWhere((g) => g.id == id);
                onGroupChanged(found);
              },
            ),

          // Selector de Planta Existente (solo Modalidad B)
          if (mode == ScanMode.healthDiagnosis && selectedGroup != null) ...[
            const SizedBox(height: 14),
            Text(
              '2. Selecciona la planta a diagnosticar',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
            const SizedBox(height: 8),
            if (loadingPlants)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(color: AppColors.primary),
              )
            else if (groupPlants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Este grupo no tiene plantas registradas todavía.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: selectedPlant?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Elige una planta del grupo',
                  prefixIcon: const Icon(
                    Icons.local_florist_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                ),
                items: groupPlants
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '${p.customName} (${p.scientificName})',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final found = groupPlants.firstWhere((p) => p.id == id);
                  onPlantChanged(found);
                },
              ),
          ],
        ],
      ),
    );
  }
}
