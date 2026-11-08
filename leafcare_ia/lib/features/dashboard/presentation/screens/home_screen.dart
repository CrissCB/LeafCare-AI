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

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // Mientras carga mostramos el indicador
        if (state is DashboardInitial || state is DashboardLoading) {
          return const Scaffold(body: LoadingIndicator());
        }

        // Si algo falló, mostramos el error con botón para reintentar
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

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final bloc = context.read<DashboardBloc>();
              // Esperamos a que termine la recarga para cerrar el indicador
              final finished = bloc.stream.firstWhere(
                (state) => state is! DashboardLoading,
              );
              bloc.add(const RefreshDashboard());
              await finished;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeader(
                    userName: loaded.userName,
                    plantsCount: loaded.plants.length,
                    alertsCount: loaded.unreadAlerts,
                    remindersCount: loaded.reminders.length,
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
                          actionLabel: loaded.plants.isEmpty
                              ? null
                              : 'Ver todas',
                          onAction: () => context.push('/plants'),
                        ),
                        const SizedBox(height: 12),
                        if (loaded.plants.isEmpty)
                          _EmptyPlants(
                            onScan: () => context.go('/scan'),
                          )
                        else
                          _PlantsRow(
                            plants: loaded.plants,
                            onTap: (plant) =>
                                context.push('/plant/${plant.id}'),
                          ),

                        const SizedBox(height: 26),

                        // ---------- RECORDATORIOS ----------
                        const _SectionTitle(title: 'Recordatorios de hoy'),
                        const SizedBox(height: 12),
                        if (loaded.reminders.isEmpty)
                          const _EmptyReminders()
                        else
                          Column(
                            children: [
                              for (final reminder in loaded.reminders)
                                ReminderTile(
                                  reminder: reminder,
                                  onComplete: () {
                                    context.read<DashboardBloc>().add(
                                      CompleteReminder(reminder.id),
                                    );
                                    _snack(
                                      context,
                                      '${reminder.action} marcado como hecho',
                                    );
                                  },
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

/// Título de sección con un enlace opcional a la derecha.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
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

/// Lista horizontal con las tarjetas de las plantas.
class _PlantsRow extends StatelessWidget {
  const _PlantsRow({required this.plants, required this.onTap});

  final List<UserPlantModel> plants;
  final ValueChanged<UserPlantModel> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: plants.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final plant = plants[index];
          return PlantCard(plant: plant, onTap: () => onTap(plant));
        },
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
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
