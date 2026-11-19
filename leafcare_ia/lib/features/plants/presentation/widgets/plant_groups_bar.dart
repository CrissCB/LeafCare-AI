import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/plants/data/models/plant_group_model.dart';

/// Barra horizontal para filtrar por grupo y administrar `plant_groups`.
class PlantGroupsBar extends StatelessWidget {
  const PlantGroupsBar({
    super.key,
    required this.groups,
    required this.totalPlantsCount,
    required this.countForGroup,
    required this.selectedGroupId,
    required this.onSelectGroup,
    required this.onCreateGroup,
    required this.onGroupOptions,
  });

  final List<PlantGroupModel> groups;
  final int totalPlantsCount;
  final int Function(String groupId) countForGroup;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelectGroup;
  final VoidCallback onCreateGroup;
  final ValueChanged<PlantGroupModel> onGroupOptions;

  @override
  Widget build(BuildContext context) {
    // Ítem 0: "Todas" | Ítems 1..N: grupos | Último ítem: "+ Grupo"
    final itemCount = groups.length + 2;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _GroupChip(
              icon: Icons.folder_rounded,
              label: 'Todas',
              count: totalPlantsCount,
              selected: selectedGroupId == null,
              onTap: () => onSelectGroup(null),
            );
          }

          if (index == itemCount - 1) {
            return _AddGroupButton(onTap: onCreateGroup);
          }

          final group = groups[index - 1];
          final isSelected = selectedGroupId == group.id;

          return _GroupChip(
            icon: group.icon,
            label: group.name,
            count: countForGroup(group.id),
            selected: isSelected,
            onTap: () => onSelectGroup(isSelected ? null : group.id),
            onLongPress: () => onGroupOptions(group),
          );
        },
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.neon : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.anthracite,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.white.withValues(alpha: 0.18)
                    : AppColors.mint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGroupButton extends StatelessWidget {
  const _AddGroupButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Nuevo grupo',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
