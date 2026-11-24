import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';

/// Fila de un recordatorio del día con doble interacción:
/// - Tocar la tarjeta navega al módulo de alertas (`/alerts`).
/// - Tocar el botón circular derecho completa el cuidado directamente.
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onComplete,
    this.isCompleting = false,
  });

  final CareReminderModel reminder;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool isCompleting;

  /// Selecciona el ícono según la acción de tratamiento.
  IconData get _icon {
    final action = reminder.treatmentAction.toLowerCase();

    if (action.contains('regar') ||
        action.contains('riego') ||
        action.contains('agua')) {
      return Icons.water_drop_rounded;
    }
    if (action.contains('abon') || action.contains('fertil')) {
      return Icons.grass_rounded;
    }
    if (action.contains('pod')) return Icons.content_cut_rounded;
    if (action.contains('pulver') || action.contains('fumig')) {
      return Icons.spa_rounded;
    }
    return Icons.checklist_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('HH:mm').format(reminder.scheduledTime);
    final plantLabel = reminder.plantName?.trim() ?? '';
    final subtitle = plantLabel.isNotEmpty
        ? '$plantLabel · Hoy · $formattedTime'
        : 'Hoy · $formattedTime';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
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

                // Acción, planta asociada y hora programada
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.treatmentAction,
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
                          Flexible(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.slate,
                              ),
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

                const SizedBox(width: 10),

                // Botón aislado para marcar como completado sin abrir /alerts
                Tooltip(
                  message: 'Marcar como hecho',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: isCompleting ? null : onComplete,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.inputBorder,
                          width: 1.5,
                        ),
                      ),
                      child: isCompleting
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
