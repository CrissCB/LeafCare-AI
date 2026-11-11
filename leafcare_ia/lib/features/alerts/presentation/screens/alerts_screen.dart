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

/// Filtros disponibles en la pantalla de alertas.
enum _AlertFilter { all, unread, read }

class _AlertsView extends StatefulWidget {
  const _AlertsView();

  @override
  State<_AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<_AlertsView> {
  final TextEditingController _searchController = TextEditingController();

  _AlertFilter _filter = _AlertFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          final filtered = _applyFilter(loaded.alerts);

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
                    filter: _filter,
                    searchController: _searchController,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onFilterChanged: (value) =>
                        setState(() => _filter = value),
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
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Sin alertas en este filtro',
                      subtitle: _query.trim().isNotEmpty
                          ? 'No encontramos alertas con esa búsqueda. Prueba con otra palabra.'
                          : _filter == _AlertFilter.unread
                          ? 'No tienes alertas sin leer. ¡Todo al día!'
                          : 'Todavía no has marcado ninguna alerta como leída.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final alert = filtered[index];

                        return Dismissible(
                          key: ValueKey('alert-${alert.id}'),
                          direction: DismissDirection.endToStart,
                          background: const _DeleteBackground(),
                          confirmDismiss: (_) => _confirmDelete(alert),
                          onDismissed: (_) {
                            context.read<AlertsBloc>().add(
                              DeleteAlert(alert.id),
                            );
                          },
                          child: _AlertCard(
                            alert: alert,
                            onTap: () {
                              if (!alert.isRead) {
                                context.read<AlertsBloc>().add(
                                  MarkAlertRead(alert.id),
                                );
                              }
                              _showAlertDetail(context, alert);
                            },
                          ),
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

  /// Devuelve solo las alertas que corresponden al filtro y a la búsqueda.
  List<AlertModel> _applyFilter(List<AlertModel> alerts) {
    final query = _query.trim().toLowerCase();

    return alerts.where((alert) {
      final matchesFilter = switch (_filter) {
        _AlertFilter.all => true,
        _AlertFilter.unread => !alert.isRead,
        _AlertFilter.read => alert.isRead,
      };

      final matchesQuery =
          query.isEmpty ||
          alert.title.toLowerCase().contains(query) ||
          alert.description.toLowerCase().contains(query) ||
          alert.summary.toLowerCase().contains(query);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  /// Pregunta antes de borrar una alerta.
  Future<bool> _confirmDelete(AlertModel alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Eliminar alerta',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${alert.title}"?',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.slate,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    return confirmed == true;
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
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.paddingOf(sheetContext).bottom,
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.read<AlertsBloc>().add(DeleteAlert(alert.id));
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Entendido'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fondo rojo que aparece al deslizar una alerta para borrarla.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.white, size: 20),
          SizedBox(width: 6),
          Text(
            'Eliminar',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado de la pantalla con el contador de alertas sin leer.
class _AlertsHeader extends StatelessWidget {
  const _AlertsHeader({
    required this.unreadCount,
    required this.total,
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
    required this.onQueryChanged,
    this.onMarkAll,
  });

  final int unreadCount;
  final int total;
  final _AlertFilter filter;
  final TextEditingController searchController;
  final ValueChanged<_AlertFilter> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
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
          const SizedBox(height: 14),
          // Filtros: todas, sin leer y leídas
          Row(
            children: [
              _AlertsFilterChip(
                label: 'Todas',
                count: total,
                selected: filter == _AlertFilter.all,
                onTap: () => onFilterChanged(_AlertFilter.all),
              ),
              const SizedBox(width: 8),
              _AlertsFilterChip(
                label: 'Sin leer',
                count: unreadCount,
                selected: filter == _AlertFilter.unread,
                onTap: () => onFilterChanged(_AlertFilter.unread),
              ),
              const SizedBox(width: 8),
              _AlertsFilterChip(
                label: 'Leídas',
                count: total - unreadCount,
                selected: filter == _AlertFilter.read,
                onTap: () => onFilterChanged(_AlertFilter.read),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Buscador de alertas por título o descripción
          TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.anthracite,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar en tus alertas',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              fillColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón redondeado para elegir el filtro de alertas.
class _AlertsFilterChip extends StatelessWidget {
  const _AlertsFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neon
              : AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$label · $count',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primaryDark : AppColors.white,
          ),
        ),
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
