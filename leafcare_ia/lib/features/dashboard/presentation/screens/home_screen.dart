import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:leafcare_ia/features/dashboard/presentation/widgets/home_header.dart';
import 'package:leafcare_ia/features/dashboard/presentation/widgets/plant_card.dart';
import 'package:leafcare_ia/features/dashboard/presentation/widgets/reminder_tile.dart';

/// Pantalla principal (pestaña "Inicio").
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardBloc()..add(const LoadDashboard()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  GoRouterDelegate? _routerDelegate;
  String _lastPath = '/dashboard';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.of(context).routerDelegate;
    if (_routerDelegate != delegate) {
      _routerDelegate?.removeListener(_onRouteChanged);
      _routerDelegate = delegate..addListener(_onRouteChanged);
      final initialPath = delegate.currentConfiguration.uri.path;
      if (initialPath.isNotEmpty) {
        _lastPath = initialPath;
      }
    }
  }

  void _onRouteChanged() {
    final currentPath = _routerDelegate?.currentConfiguration.uri.path ?? '';
    if (currentPath == '/dashboard' && _lastPath != '/dashboard') {
      if (mounted) {
        context.read<DashboardBloc>().add(const RefreshDashboard());
      }
    }
    if (currentPath.isNotEmpty) {
      _lastPath = currentPath;
    }
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _pushAndRefresh(BuildContext context, String route) async {
    await context.push(route);
    if (context.mounted) {
      context.read<DashboardBloc>().add(const RefreshDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) =>
          current is DashboardLoaded &&
          current.notice != null &&
          previous != current,
      listener: (context, state) {
        if (state is DashboardLoaded && state.notice != null) {
          _snack(context, state.notice!, isError: state.noticeIsError);
        }
      },
      builder: (context, state) {
        if (state is DashboardInitial || state is DashboardLoading) {
          return const Scaffold(body: LoadingIndicator());
        }

        if (state is DashboardError) {
          return Scaffold(
            body: EmptyStateView(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudo cargar',
              subtitle: state.message,
              onRetry: () =>
                  context.read<DashboardBloc>().add(const LoadDashboard()),
            ),
          );
        }

        final loaded = state as DashboardLoaded;
        final hasMorePlants = loaded.totalPlantsCount > loaded.topPlants.length;

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final bloc = context.read<DashboardBloc>();
              bloc.add(const RefreshDashboard());
              await bloc.stream.firstWhere(
                (s) => s is DashboardLoaded || s is DashboardError,
              );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeader(
                    userName: loaded.userName,
                    avatarUrl: loaded.avatarUrl,
                    alertsCount: loaded.unreadAlertsCount,
                    onNavigateReturn: () => context.read<DashboardBloc>().add(
                      const RefreshDashboard(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- MIS PLANTAS ----------
                        _SectionTitle(
                          title: 'Mis plantas',
                          count: loaded.totalPlantsCount,
                          actionLabel: loaded.topPlants.isEmpty
                              ? null
                              : 'Ver todas',
                          onAction: () => _pushAndRefresh(context, '/plants'),
                        ),
                        const SizedBox(height: 12),
                        if (loaded.topPlants.isEmpty)
                          _EmptyPlants(onScan: () => context.go('/scan'))
                        else
                          _PlantsRow(
                            plants: loaded.topPlants,
                            totalPlantsCount: loaded.totalPlantsCount,
                            showSeeMore: hasMorePlants,
                            onTapPlant: (plant) =>
                                _pushAndRefresh(context, '/plant/${plant.id}'),
                            onTapSeeMore: () =>
                                _pushAndRefresh(context, '/plants'),
                          ),

                        const SizedBox(height: 26),

                        // ---------- CONSEJO DEL DÍA ----------
                        _DailyTipCard(tip: loaded.dailyTip),

                        const SizedBox(height: 26),

                        // ---------- RECORDATORIOS DE HOY ----------
                        _SectionTitle(
                          title: 'Recordatorios de hoy',
                          actionLabel: 'Gestionar',
                          onAction: () => context.go('/alerts'),
                        ),
                        const SizedBox(height: 12),
                        if (loaded.todayReminders.isEmpty)
                          const _EmptyReminders()
                        else
                          Column(
                            children: [
                              for (final reminder in loaded.todayReminders)
                                ReminderTile(
                                  reminder: reminder,
                                  isCompleting: loaded.completingReminderIds
                                      .contains(reminder.id),
                                  onTap: () => context.go('/alerts'),
                                  onComplete: () => context
                                      .read<DashboardBloc>()
                                      .add(CompleteReminder(reminder.id)),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Título de sección con contador opcional junto al texto y acción a la derecha.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.anthracite,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Lista horizontal con las tarjetas de las primeras plantas y botón "Ver más".
class _PlantsRow extends StatelessWidget {
  const _PlantsRow({
    required this.plants,
    required this.totalPlantsCount,
    required this.showSeeMore,
    required this.onTapPlant,
    required this.onTapSeeMore,
  });

  final List<UserPlantModel> plants;
  final int totalPlantsCount;
  final bool showSeeMore;
  final ValueChanged<UserPlantModel> onTapPlant;
  final VoidCallback onTapSeeMore;

  @override
  Widget build(BuildContext context) {
    final itemCount = plants.length + (showSeeMore ? 1 : 0);
    final remainingCount = totalPlantsCount - plants.length;

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (showSeeMore && index == plants.length) {
            return _SeeMorePlantsCard(
              remainingCount: remainingCount,
              onTap: onTapSeeMore,
            );
          }

          final plant = plants[index];
          return PlantCard(plant: plant, onTap: () => onTapPlant(plant));
        },
      ),
    );
  }
}

/// Tarjeta final del carrusel cuando el usuario tiene más de 5 plantas.
class _SeeMorePlantsCard extends StatelessWidget {
  const _SeeMorePlantsCard({required this.remainingCount, required this.onTap});

  final int remainingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 136,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ver más',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (remainingCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '+$remainingCount ${remainingCount == 1 ? 'planta' : 'plantas'}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con el consejo diario provisto desde el estado del Dashboard.
class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.neon,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo del día',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.white.withValues(alpha: 0.88),
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

/// Tarjeta que se muestra cuando el usuario todavía no tiene plantas.
class _EmptyPlants extends StatelessWidget {
  const _EmptyPlants({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aún no tienes plantas',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escanea tu primera planta y la inteligencia artificial te dirá cómo cuidarla.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Escanear mi primera planta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso cuando no hay cuidados pendientes para hoy.
class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No tienes cuidados pendientes hoy. ¡Tus plantas están al día!',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
