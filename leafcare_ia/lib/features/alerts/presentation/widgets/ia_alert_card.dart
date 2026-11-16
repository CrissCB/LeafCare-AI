import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_model.dart';

/// Tarjeta informativa de una alerta generada por el motor de IA.
class IaAlertCard extends StatelessWidget {
  const IaAlertCard({
    super.key,
    required this.alert,
    required this.onTapCard,
    this.onDelete,
    this.onRestore,
  });

  final IaAlertModel alert;
  final VoidCallback onTapCard;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (targetDay == today) {
      final h = diff.inHours;
      return h == 1 ? 'Hace 1 hora' : 'Hace $h horas';
    }
    if (targetDay == yesterday) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = alert.statusColor;
    final isUnread = !alert.isRead && !alert.isDeleted;
    final isDeleted = alert.isDeleted;
    final imageUrl = alert.plantImageUrl?.trim() ?? '';
    final plantName = (alert.plantName?.trim().isNotEmpty == true)
        ? alert.plantName!.trim()
        : 'Planta monitoreada';

    final cardBg = isUnread
        ? statusColor.withValues(alpha: 0.06)
        : (isDeleted
              ? AppColors.white.withValues(alpha: 0.65)
              : AppColors.white);

    final borderColor = isUnread
        ? statusColor.withValues(alpha: 0.35)
        : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTapCard,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: isUnread ? 1.2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la tarjeta: Imagen + Badges + Botón X
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen de la planta
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.eco_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            )
                          : const Icon(
                              Icons.eco_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Badges de estado + título del problema
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Chip de estado con color
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDeleted
                                      ? AppColors.slateLight
                                      : statusColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  alert.statusLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),

                              // Chip de resumen corto (ej. "IA - Falta de agua")
                              if (alert.shortDescription.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    alert.shortDescription,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Título del problema
                          Text(
                            alert.issueTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDeleted
                                  ? AppColors.slate
                                  : AppColors.anthracite,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón X superior derecho (activas) o botón Restaurar (eliminadas)
                    if (onDelete != null && !isDeleted) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onDelete,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.slateLight.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ] else if (onRestore != null && isDeleted) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onRestore,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.restore_rounded,
                                size: 14,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Restaurar',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Análisis formal (full_summary_ia)
                if (alert.fullSummaryIa.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Text(
                      alert.fullSummaryIa,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                ],

                // Pie informativo: Punto de estado + Nombre de planta + Marca de tiempo
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDeleted ? AppColors.slateLight : statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          '$plantName  ·  ${_formatRelativeTime(alert.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slateLight,
                          ),
                        ),
                      ),
                      if (isDeleted)
                        Text(
                          'Eliminada',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slateLight,
                          ),
                        ),
                    ],
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
