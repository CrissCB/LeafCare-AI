import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/alerts/data/models/alert_model.dart';
import 'package:leafcare_ia/features/alerts/presentation/bloc/alerts_bloc.dart';

/// Pantalla de alertas generadas por la inteligencia artificial.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlertsBloc()..add(const LoadAlerts()),
      child: const _AlertsView(),
    );
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) {
          if (state is AlertsInitial || state is AlertsLoading) {
            return const LoadingIndicator();
          }

          if (state is AlertsError) {
            return EmptyStateView(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudieron cargar',
              subtitle: state.message,
              onRetry: () =>
                  context.read<AlertsBloc>().add(const LoadAlerts()),
            );
          }

          final loaded = state as AlertsLoaded;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final bloc = context.read<AlertsBloc>();
              final finished = bloc.stream.firstWhere(
                (state) => state is! AlertsLoading,
              );
              bloc.add(const RefreshAlerts());
              await finished;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _AlertsHeader(
                    unreadCount: loaded.unreadCount,
                    total: loaded.alerts.length,
                    onMarkAll: loaded.unreadCount == 0
                        ? null
                        : () => context.read<AlertsBloc>().add(
                            const MarkAllAlertsRead(),
                          ),
                  ),
                ),
                if (loaded.alerts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.notifications_off_rounded,
                      title: 'Todo en orden',
                      subtitle:
                          'No tienes alertas por ahora. Cuando la inteligencia artificial detecte algo en tus plantas, aparecerá aquí.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    sliver: SliverList.separated(
                      itemCount: loaded.alerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final alert = loaded.alerts[index];

                        return _AlertCard(
                          alert: alert,
                          onTap: () {
                            if (!alert.isRead) {
                              context.read<AlertsBloc>().add(
                                MarkAlertRead(alert.id),
                              );
                            }
                            _showAlertDetail(context, alert);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Muestra el resumen completo de la alerta en una hoja inferior.
  void _showAlertDetail(BuildContext context, AlertModel alert) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Análisis de la IA',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                alert.title,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.anthracite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alert.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.slate,
                ),
              ),
              if (alert.summary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    alert.summary,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Encabezado de la pantalla con el contador de alertas sin leer.
class _AlertsHeader extends StatelessWidget {
  const _AlertsHeader({
    required this.unreadCount,
    required this.total,
    this.onMarkAll,
  });

  final int unreadCount;
  final int total;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 18,
        20,
        20,
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
          Text(
            'Alertas',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Sin alertas por ahora'
                : unreadCount == 0
                ? 'Todas las alertas están leídas'
                : '$unreadCount sin leer de $total',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.78),
            ),
          ),
          if (onMarkAll != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onMarkAll,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Marcar todas como leídas'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neon,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppColors.white.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de una alerta.
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});

  final AlertModel alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(alert.statusColorHex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.isRead ? AppColors.border : color.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono de la alerta con su color
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.anthracite,
                          ),
                        ),
                      ),
                      if (!alert.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (alert.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      alert.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(alert.created),
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
      ),
    );
  }

  /// Fecha corta: "Hoy · 14:30", "Ayer · 09:10" o "27/10/2026".
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (difference == 0) return 'Hoy · $time';
    if (difference == 1) return 'Ayer · $time';

    final dayText = date.day.toString().padLeft(2, '0');
    final monthText = date.month.toString().padLeft(2, '0');
    return '$dayText/$monthText/${date.year}';
  }

  /// Convierte "#DC2626" en un Color de Flutter.
  Color _colorFromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? AppColors.error : Color(parsed);
  }
}
