import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';
import 'package:leafcare_ia/features/profile/data/datasources/stats_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/stats_model.dart';

/// Pantalla con un resumen visual del cuidado de las plantas.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsDatasource _datasource = StatsDatasource();
  late Future<StatsModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _datasource.fetchStats();
  }

  void _reload() {
    setState(() {
      _future = _datasource.fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const SubPageHeader(
            title: 'Estadísticas',
            subtitle: 'Un vistazo al cuidado de tus plantas.',
            icon: Icons.bar_chart_rounded,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    return FutureBuilder<StatsModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return EmptyStateView(
            icon: Icons.bar_chart_rounded,
            title: 'No se pudieron cargar las estadísticas',
            subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
            onRetry: _reload,
          );
        }

        final stats = snapshot.data!;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _reload();
            await _future;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _SummaryGrid(stats: stats),
              const SizedBox(height: 22),
              const _SectionTitle('Estado de tus plantas'),
              const SizedBox(height: 10),
              _HealthCard(stats: stats),
              const SizedBox(height: 22),
              const _SectionTitle('Recordatorios'),
              const SizedBox(height: 10),
              _RemindersCard(stats: stats),
              const SizedBox(height: 22),
              const _SectionTitle('Últimos análisis'),
              const SizedBox(height: 10),
              if (stats.recentScans.isEmpty)
                const _EmptyRecentScans()
              else
                for (final scan in stats.recentScans)
                  _RecentScanTile(scan: scan),
            ],
          ),
        );
      },
    );
  }
}

/// Cuatro tarjetas con los números principales.
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});

  final StatsModel stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.local_florist_rounded,
                value: '${stats.plantsCount}',
                label: 'Plantas',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.auto_awesome_rounded,
                value: '${stats.scansCount}',
                label: 'Análisis',
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.notifications_active_rounded,
                value: '${stats.unreadAlerts}',
                label: 'Alertas sin leer',
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.task_alt_rounded,
                value: '${stats.pendingReminders}',
                label: 'Cuidados pendientes',
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta pequeña con un número y su etiqueta.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.slateLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barras con la cantidad de plantas por estado de salud.
class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.stats});

  final StatsModel stats;

  @override
  Widget build(BuildContext context) {
    if (stats.healthStats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Todavía no tienes plantas registradas. Escanea tu primera planta para ver sus estadísticas.',
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.4,
            color: AppColors.primaryDark,
          ),
        ),
      );
    }

    final total = stats.healthTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final stat in stats.healthStats) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _colorFromHex(stat.colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.anthracite,
                    ),
                  ),
                ),
                Text(
                  '${stat.count}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.anthracite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : stat.count / total,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  _colorFromHex(stat.colorHex),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Color _colorFromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? AppColors.slate : Color(parsed);
  }
}

/// Barra con el avance de los recordatorios completados.
class _RemindersCard extends StatelessWidget {
  const _RemindersCard({required this.stats});

  final StatsModel stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.remindersCount;
    final ratio = total == 0 ? 0.0 : stats.completedReminders / total;
    final percent = (ratio * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent%',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'de cuidados completados',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.slateLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LegendDot(
                color: AppColors.primary,
                label: 'Hechos: ${stats.completedReminders}',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: const Color(0xFFD97706),
                label: 'Pendientes: ${stats.pendingReminders}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Punto de color con una etiqueta.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }
}

/// Fila con un análisis reciente.
class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile({required this.scan});

  final RecentScanStat scan;

  @override
  Widget build(BuildContext context) {
    final scoreColor = scan.healthScore >= 70
        ? AppColors.primary
        : scan.healthScore >= 40
        ? const Color(0xFFD97706)
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${scan.healthScore}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.plantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${scan.keyword} · ${_formatDate(scan.created)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.slateLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// Aviso cuando todavía no hay análisis.
class _EmptyRecentScans extends StatelessWidget {
  const _EmptyRecentScans();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Todavía no hay análisis. Escanea una planta para empezar a ver su historial aquí.',
        style: GoogleFonts.inter(
          fontSize: 12,
          height: 1.4,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

/// Título de sección.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.anthracite,
      ),
    );
  }
}
