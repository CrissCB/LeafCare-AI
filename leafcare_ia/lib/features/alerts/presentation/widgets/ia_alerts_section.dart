import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_model.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/ia_alert_card.dart';

/// Organiza el listado de Alertas IA en sus 3 estados:
/// 1. Sin leer (con contador)
/// 2. Anteriores / ya revisadas (sin contador)
/// 3. Eliminadas hace menos de 7 días (sin contador)
class IaAlertsSection extends StatelessWidget {
  const IaAlertsSection({
    super.key,
    required this.unreadAlerts,
    required this.readAlerts,
    required this.deletedRecentAlerts,
    required this.onTapAlert,
    required this.onDeleteAlert,
    required this.onRestoreAlert,
  });

  final List<IaAlertModel> unreadAlerts;
  final List<IaAlertModel> readAlerts;
  final List<IaAlertModel> deletedRecentAlerts;
  final ValueChanged<IaAlertModel> onTapAlert;
  final ValueChanged<IaAlertModel> onDeleteAlert;
  final ValueChanged<IaAlertModel> onRestoreAlert;

  @override
  Widget build(BuildContext context) {
    final isCompletelyEmpty =
        unreadAlerts.isEmpty &&
        readAlerts.isEmpty &&
        deletedRecentAlerts.isEmpty;

    if (isCompletelyEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin alertas de IA',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'El análisis continuo no ha detectado anomalías en tus plantas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SIN LEER (único estado con contador)
        if (unreadAlerts.isNotEmpty) ...[
          _GroupHeader(
            label: 'SIN LEER · ${unreadAlerts.length}',
            color: AppColors.error,
          ),
          const SizedBox(height: 10),
          for (final alert in unreadAlerts)
            IaAlertCard(
              alert: alert,
              onTapCard: () => onTapAlert(alert),
              onDelete: () => onDeleteAlert(alert),
            ),
          const SizedBox(height: 10),
        ],

        // 2. ANTERIORES (revisadas)
        if (readAlerts.isNotEmpty) ...[
          const _GroupHeader(label: 'ANTERIORES', color: AppColors.slate),
          const SizedBox(height: 10),
          for (final alert in readAlerts)
            IaAlertCard(
              alert: alert,
              onTapCard: () => onTapAlert(alert),
              onDelete: () => onDeleteAlert(alert),
            ),
          const SizedBox(height: 10),
        ],

        // 3. ELIMINADAS (< 7 días)
        if (deletedRecentAlerts.isNotEmpty) ...[
          const _GroupHeader(
            label: 'ELIMINADAS · ÚLTIMOS 7 DÍAS',
            color: AppColors.slateLight,
          ),
          const SizedBox(height: 10),
          for (final alert in deletedRecentAlerts)
            IaAlertCard(
              alert: alert,
              onTapCard: () => onTapAlert(alert),
              onRestore: () => onRestoreAlert(alert),
            ),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: color,
      ),
    );
  }
}
