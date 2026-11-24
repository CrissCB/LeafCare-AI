import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/stats/data/models/stats_summary_model.dart';

/// Cabecera verde degradada con el índice general de salud del jardín.
class StatsHeroHeader extends StatelessWidget {
  const StatsHeroHeader({super.key, required this.summary});

  final StatsSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final hasScans = summary.totalScans > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 14,
        20,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estadísticas',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'Rendimiento y salud de tu colección',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tarjeta translúcida con salud promedio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.neon.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.neon,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salud promedio del jardín',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasScans
                            ? 'Basado en ${summary.totalScans} análisis realizados'
                            : 'Realiza tu primer escaneo para calcular',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  hasScans ? '${summary.averageHealthScore}%' : '--',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuadrícula 2x2 con las 4 métricas clave solicitadas.
class StatsKpiGrid extends StatelessWidget {
  const StatsKpiGrid({super.key, required this.summary});

  final StatsSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.local_florist_outlined,
                iconBg: AppColors.mint,
                iconColor: AppColors.primary,
                value: '${summary.totalPlants}',
                label: 'Plantas totales',
                onTap: () => context.push('/plants'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiTile(
                icon: Icons.document_scanner_outlined,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                value: '${summary.totalScans}',
                label: 'Análisis hechos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.auto_awesome_outlined,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: AppColors.error,
                value: '${summary.unreadIaAlerts}',
                label: 'Alertas sin leer',
                onTap: () => context.go('/alerts?tab=ia'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiTile(
                icon: Icons.event_available_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                value: '${summary.pendingReminders}',
                label: 'Cuidados pendientes',
                onTap: () => context.go('/alerts?tab=reminders'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: AppColors.slateLight,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.anthracite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Distribución visual por estado de salud de las plantas.
class PlantHealthDistributionCard extends StatelessWidget {
  const PlantHealthDistributionCard({super.key, required this.distribution});

  final PlantHealthDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final total = distribution.total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estado de tus plantas',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.anthracite,
                ),
              ),
              Text(
                '$total ${total == 1 ? 'planta' : 'plantas'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra segmentada apilada
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? Container(color: AppColors.border)
                  : Row(
                      children: [
                        if (distribution.healthyCount > 0)
                          Expanded(
                            flex: distribution.healthyCount,
                            child: Container(color: AppColors.primary),
                          ),
                        if (distribution.attentionCount > 0)
                          Expanded(
                            flex: distribution.attentionCount,
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                        if (distribution.sickCount > 0)
                          Expanded(
                            flex: distribution.sickCount,
                            child: Container(color: AppColors.error),
                          ),
                        if (distribution.unassessedCount > 0)
                          Expanded(
                            flex: distribution.unassessedCount,
                            child: Container(color: AppColors.slateLight),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          _StatusLegendRow(
            color: AppColors.primary,
            label: 'Saludables',
            count: distribution.healthyCount,
            percent: distribution.percentFor(distribution.healthyCount),
          ),
          const SizedBox(height: 10),
          _StatusLegendRow(
            color: const Color(0xFFF59E0B),
            label: 'Requieren atención',
            count: distribution.attentionCount,
            percent: distribution.percentFor(distribution.attentionCount),
          ),
          const SizedBox(height: 10),
          _StatusLegendRow(
            color: AppColors.error,
            label: 'Enfermas / Críticas',
            count: distribution.sickCount,
            percent: distribution.percentFor(distribution.sickCount),
          ),
          if (distribution.unassessedCount > 0) ...[
            const SizedBox(height: 10),
            _StatusLegendRow(
              color: AppColors.slateLight,
              label: 'Sin evaluar',
              count: distribution.unassessedCount,
              percent: distribution.percentFor(distribution.unassessedCount),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLegendRow extends StatelessWidget {
  const _StatusLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
  });

  final Color color;
  final String label;
  final int count;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.anthracite,
            ),
          ),
        ),
        Text(
          '$count  ($percent%)',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }
}

/// Porcentaje de cumplimiento de cuidados y alertas IA revisadas.
class CompletionProgressCard extends StatelessWidget {
  const CompletionProgressCard({super.key, required this.summary});

  final StatsSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cumplimiento y seguimiento',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 14),
          _ProgressMetricRow(
            title: 'Cuidados completados',
            subtitle:
                '${summary.completedReminders} de ${summary.totalReminders} recordatorios',
            percent: summary.remindersCompletionPercent,
            ratio: summary.remindersCompletionRatio,
            barColor: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _ProgressMetricRow(
            title: 'Alertas IA atendidas',
            subtitle:
                '${summary.readIaAlerts} de ${summary.totalActiveIaAlerts} alertas revisadas',
            percent: summary.iaAlertsReviewedPercent,
            ratio: summary.iaAlertsReviewedRatio,
            barColor: const Color(0xFF0284C7),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetricRow extends StatelessWidget {
  const _ProgressMetricRow({
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.ratio,
    required this.barColor,
  });

  final String title;
  final String subtitle;
  final int percent;
  final double ratio;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.slateLight,
                  ),
                ),
              ],
            ),
            Text(
              '$percent%',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

/// Listado de los últimos escaneos con porcentaje de salud, nombre y summary_keyword.
class RecentScansSection extends StatelessWidget {
  const RecentScansSection({super.key, required this.scans});

  final List<RecentScanItemModel> scans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos análisis realizados',
          style: GoogleFonts.outfit(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: AppColors.anthracite,
          ),
        ),
        const SizedBox(height: 10),
        if (scans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Aún no tienes análisis registrados. Escanea una planta desde el botón central para ver su historial aquí.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate),
            ),
          )
        else
          for (final scan in scans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: scan.plantId.isNotEmpty
                      ? () => context.push('/plant/${scan.plantId}')
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        // Foto del escaneo
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: scan.scannedImageUrl.isNotEmpty
                              ? Image.network(
                                  scan.scannedImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.eco_rounded,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.eco_rounded,
                                  color: AppColors.primary,
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Nombre de la planta + summary_keyword + fecha
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.plantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.anthracite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.mint,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      scan.summaryKeyword,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(scan.createdAt),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.slateLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Porcentaje de salud (health_score)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scan.scoreColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${scan.healthScore}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: scan.scoreColor,
                                ),
                              ),
                              Text(
                                'Salud',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: scan.scoreColor,
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
            ),
      ],
    );
  }
}
