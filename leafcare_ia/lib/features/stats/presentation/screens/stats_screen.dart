import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/stats/data/datasources/stats_datasource.dart';
import 'package:leafcare_ia/features/stats/data/repositories/stats_repository.dart';
import 'package:leafcare_ia/features/stats/presentation/bloc/stats_bloc.dart';
import 'package:leafcare_ia/features/stats/presentation/widgets/stats_sections.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatsBloc(
        repository: StatsRepository(
          datasource: StatsDatasource(
            supabaseClient: const AppSupabaseClient(),
          ),
        ),
      )..add(const LoadStatsRequested()),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state is StatsLoading || state is StatsInitial) {
            return const LoadingIndicator();
          }

          if (state is StatsError) {
            return EmptyStateView(
              icon: Icons.bar_chart_rounded,
              title: 'No se pudieron cargar las estadísticas',
              subtitle: state.message,
              onRetry: () =>
                  context.read<StatsBloc>().add(const LoadStatsRequested()),
            );
          }

          final summary = (state as StatsLoaded).summary;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final bloc = context.read<StatsBloc>()
                ..add(const RefreshStatsRequested());
              await bloc.stream.firstWhere((s) => s is StatsLoaded);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: StatsHeroHeader(summary: summary)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatsKpiGrid(summary: summary),
                        const SizedBox(height: 16),
                        PlantHealthDistributionCard(
                          distribution: summary.healthDistribution,
                        ),
                        const SizedBox(height: 16),
                        CompletionProgressCard(summary: summary),
                        const SizedBox(height: 20),
                        RecentScansSection(scans: summary.recentScans),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
