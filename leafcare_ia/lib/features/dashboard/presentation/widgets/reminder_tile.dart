import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';

/// Fila de un recordatorio de cuidado con su botón de "hecho".
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    required this.onComplete,
  });

  final CareReminderModel reminder;
  final VoidCallback onComplete;

  /// Elige el ícono según la acción del recordatorio.
  IconData get _icon {
    final action = reminder.action.toLowerCase();

    if (action.contains('regar') || action.contains('agua')) {
      return Icons.water_drop_rounded;
    }
    if (action.contains('abon')) return Icons.grass_rounded;
    if (action.contains('pod')) return Icons.content_cut_rounded;
    if (action.contains('pulver') || action.contains('fumig')) {
      return Icons.spa_rounded;
    }
    return Icons.checklist_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Ícono del tipo de cuidado
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),

          // Texto del recordatorio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.action,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Hoy · ${DateFormat('HH:mm').format(reminder.scheduledTime)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.slate,
                      ),
                    ),
                    if (reminder.isIaGenerated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neon12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'IA',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Botón para marcar como completado
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inputBorder, width: 1.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
