import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/alerts/data/models/care_reminder_item_model.dart';

/// Tarjeta de recordatorio con checkbox, foto de planta, ícono de cuidado y botón +1h.
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.showWeekdayPrefix,
    required this.isBusy,
    required this.onTapCard,
    required this.onToggleComplete,
    required this.onSnoozeOneHour,
  });

  final CareReminderItemModel reminder;
  final bool showWeekdayPrefix;
  final bool isBusy;
  final VoidCallback onTapCard;
  final VoidCallback onToggleComplete;
  final VoidCallback onSnoozeOneHour;

  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _formatSchedule() {
    final time = DateFormat('HH:mm').format(reminder.scheduledTime);
    if (!showWeekdayPrefix) return time;

    final dayName = _weekdays[reminder.scheduledTime.weekday - 1];
    return '$dayName ${reminder.scheduledTime.day} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCompleted = reminder.isCompleted;
    final isLate = reminder.isLateAt(now);
    final canSnooze = reminder.canSnoozeAt(now);
    final snoozeInProgress = reminder.isSnoozeInProgressAt(now);
    final iconOpt = reminder.iconOption;

    final plantName = reminder.plantName?.trim() ?? '';
    final fullTitle = plantName.isNotEmpty
        ? '${reminder.treatmentAction} · $plantName'
        : reminder.treatmentAction;

    final imageUrl = reminder.plantImageUrl?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isCompleted
            ? AppColors.white.withValues(alpha: 0.72)
            : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isBusy ? null : onTapCard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLate
                    ? AppColors.error.withValues(alpha: 0.35)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                // 1. Checkbox cuadrado redondeado
                GestureDetector(
                  onTap: (isBusy || isCompleted) ? null : onToggleComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary.withValues(alpha: 0.75)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.primary.withValues(alpha: 0.75)
                            : AppColors.inputBorder,
                        width: 1.6,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Foto cuadrada redondeada de la planta
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.eco_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 10),

                // 3. Ícono representativo + Título + Hora (con advertencia si +1h)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            iconOpt.icon,
                            size: 15,
                            color: isCompleted
                                ? AppColors.slateLight
                                : iconOpt.accentColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              fullTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? AppColors.slateLight
                                    : AppColors.anthracite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Hora (cambia de diseño si se aumentó +1 hora)
                          if (reminder.hasExtraHours && !isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.update_rounded,
                                    size: 11,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${_formatSchedule()} (+${reminder.snoozeHoursAdded}h)',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              _formatSchedule(),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slateLight,
                              ),
                            ),

                          // Etiqueta de Tardío al finalizar el día
                          if (isLate)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Tardío',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),

                          // Etiqueta IA si fue generado automáticamente
                          if (reminder.isIaGenerated)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'IA →',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),

                          // Indicador de frecuencia si es recurrente
                          if (reminder.isRecurrent &&
                              reminder.recurrenceDays != null)
                            Text(
                              'Cada ${reminder.recurrenceDays}d',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.slateLight,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Botón circular derecho "+1 hora"
                if (!isCompleted) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: canSnooze
                        ? 'Añadir 1 hora al recordatorio'
                        : snoozeInProgress
                        ? 'Hora extra en curso (se habilitará al cumplirse)'
                        : 'No disponible para posponer',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: (isBusy || !canSnooze) ? null : onSnoozeOneHour,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: canSnooze ? AppColors.mint : AppColors.pageBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: canSnooze
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : AppColors.border,
                          ),
                        ),
                        child: isBusy
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: canSnooze
                                    ? AppColors.primary
                                    : AppColors.slateLight,
                              ),
                      ),
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
