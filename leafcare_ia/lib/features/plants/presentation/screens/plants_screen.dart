import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/utils/health_status_colors.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/plants/data/models/plant_group_model.dart';
import 'package:leafcare_ia/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:leafcare_ia/features/plants/presentation/widgets/group_form_sheet.dart';
import 'package:leafcare_ia/features/plants/presentation/widgets/plant_groups_bar.dart';

/// Pantalla "Mis plantas" (`/plants`): colección completa, grupos y filtros.
class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlantsBloc()..add(const LoadPlants()),
      child: const _PlantsView(),
    );
  }
}

class _PlantsView extends StatefulWidget {
  const _PlantsView();

  @override
  State<_PlantsView> createState() => _PlantsViewState();
}

class _PlantsViewState extends State<_PlantsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool isError = false}) {
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

  Future<void> _openCreateGroup() async {
    final result = await showGroupFormSheet(context);
    if (result == null || !mounted) return;

    context.read<PlantsBloc>().add(
      CreatePlantGroup(name: result.name, iconName: result.iconName),
    );
  }

  Future<void> _openGroupOptions(PlantGroupModel group) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(group.icon, color: AppColors.primary),
              title: Text(
                group.name,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Administrar grupo'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Editar nombre o ícono'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: const Text(
                'Eliminar grupo',
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text('Las plantas quedarán sin grupo'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'edit') {
      final result = await showGroupFormSheet(context, existingGroup: group);
      if (result == null || !mounted) return;
      context.read<PlantsBloc>().add(
        UpdatePlantGroup(
          groupId: group.id,
          name: result.name,
          iconName: result.iconName,
        ),
      );
    } else if (action == 'delete') {
      context.read<PlantsBloc>().add(DeletePlantGroup(group.id));
    }
  }

  Future<void> _openAssignGroupSheet(
    UserPlantModel plant,
    List<PlantGroupModel> groups,
  ) async {
    if (groups.isEmpty) {
      _snack('Crea primero un grupo usando "+ Nuevo grupo".');
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Mover "${plant.customName}" a grupo',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            if (plant.groupId != null)
              ListTile(
                leading: const Icon(
                  Icons.folder_off_outlined,
                  color: AppColors.slate,
                ),
                title: const Text('Sin grupo'),
                onTap: () => Navigator.pop(context, '__none__'),
              ),
            for (final group in groups)
              ListTile(
                leading: Icon(group.icon, color: AppColors.primary),
                title: Text(group.name),
                trailing: plant.groupId == group.id
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, group.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    final targetGroupId = selected == '__none__' ? null : selected;
    if (targetGroupId == plant.groupId) return;

    context.read<PlantsBloc>().add(
      AssignPlantGroup(plantId: plant.id, groupId: targetGroupId),
    );
  }

  Future<void> _openPlantDetail(String plantId) async {
    await context.push('/plant/$plantId');
    if (mounted) {
      context.read<PlantsBloc>().add(const RefreshPlants());
    }
  }

  String _sortLabel(PlantSort sort) {
    switch (sort) {
      case PlantSort.recent:
        return 'Recientes';
      case PlantSort.name:
        return 'Nombre';
      case PlantSort.health:
        return 'Estado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const SubPageHeader(
            title: 'Mis plantas',
            subtitle:
                'Organiza por grupos y consulta el estado de cada planta.',
            icon: Icons.local_florist_rounded,
          ),
          Expanded(
            child: BlocConsumer<PlantsBloc, PlantsState>(
              listenWhen: (previous, current) =>
                  current is PlantsLoaded &&
                  current.notice != null &&
                  previous != current,
              listener: (context, state) {
                if (state is PlantsLoaded && state.notice != null) {
                  _snack(state.notice!, isError: state.noticeIsError);
                }
              },
              builder: (context, state) {
                if (state is PlantsInitial || state is PlantsLoading) {
                  return const LoadingIndicator();
                }

                if (state is PlantsError) {
                  return EmptyStateView(
                    icon: Icons.wifi_off_rounded,
                    title: 'No se pudieron cargar tus plantas',
                    subtitle: state.message,
                    onRetry: () =>
                        context.read<PlantsBloc>().add(const LoadPlants()),
                  );
                }

                final loaded = state as PlantsLoaded;
                final plants = loaded.filteredPlants;
                final groupPlants = loaded.plantsInSelectedGroup;
                final healthLabels = loaded.availableHealthLabels;
                final activeGroup = loaded.findGroupById(
                  loaded.selectedGroupId,
                );

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final bloc = context.read<PlantsBloc>();
                    bloc.add(const RefreshPlants());
                    await bloc.stream.firstWhere(
                      (s) => s is PlantsLoaded || s is PlantsError,
                    );
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Barra de grupos
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: PlantGroupsBar(
                            groups: loaded.groups,
                            totalPlantsCount: loaded.allPlants.length,
                            countForGroup: loaded.countPlantsInGroup,
                            selectedGroupId: loaded.selectedGroupId,
                            onSelectGroup: (groupId) => context
                                .read<PlantsBloc>()
                                .add(SelectPlantGroup(groupId)),
                            onCreateGroup: _openCreateGroup,
                            onGroupOptions: _openGroupOptions,
                          ),
                        ),
                      ),

                      // Buscador, filtros de salud y ordenamiento
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _searchController,
                                onChanged: (value) => context
                                    .read<PlantsBloc>()
                                    .add(SearchPlantsChanged(value)),
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre o especie',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: loaded.searchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Limpiar búsqueda',
                                          onPressed: () {
                                            _searchController.clear();
                                            context.read<PlantsBloc>().add(
                                              const SearchPlantsChanged(''),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (healthLabels.isNotEmpty) ...[
                                SizedBox(
                                  height: 34,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: healthLabels.length + 1,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return _FilterPill(
                                          label: 'Todos los estados',
                                          count: groupPlants.length,
                                          selected:
                                              loaded.selectedHealthFilter ==
                                              null,
                                          onTap: () =>
                                              context.read<PlantsBloc>().add(
                                                const SelectHealthFilter(null),
                                              ),
                                        );
                                      }

                                      final label = healthLabels[index - 1];
                                      final count = groupPlants
                                          .where(
                                            (p) => p.healthStatusLabel == label,
                                          )
                                          .length;
                                      final isSelected =
                                          loaded.selectedHealthFilter == label;

                                      return _FilterPill(
                                        label: label,
                                        count: count,
                                        selected: isSelected,
                                        onTap: () =>
                                            context.read<PlantsBloc>().add(
                                              SelectHealthFilter(
                                                isSelected ? null : label,
                                              ),
                                            ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Conteo y selector de orden
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      loaded.allPlants.isEmpty
                                          ? 'Todavía no tienes plantas'
                                          : '${plants.length} de ${groupPlants.length} plantas'
                                                '${activeGroup != null ? ' en ${activeGroup.name}' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.slateLight,
                                      ),
                                    ),
                                  ),
                                  if (activeGroup != null) ...[
                                    IconButton(
                                      tooltip: 'Configurar grupo',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _openGroupOptions(activeGroup),
                                      icon: const Icon(
                                        Icons.settings_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  PopupMenuButton<PlantSort>(
                                    initialValue: loaded.sort,
                                    tooltip: 'Ordenar plantas',
                                    onSelected: (value) => context
                                        .read<PlantsBloc>()
                                        .add(ChangePlantSort(value)),
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: PlantSort.recent,
                                        child: Text('Más recientes'),
                                      ),
                                      PopupMenuItem(
                                        value: PlantSort.name,
                                        child: Text('Nombre (A-Z)'),
                                      ),
                                      PopupMenuItem(
                                        value: PlantSort.health,
                                        child: Text('Estado de salud'),
                                      ),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.sort_rounded,
                                            size: 15,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _sortLabel(loaded.sort),
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_drop_down_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Lista o estados vacíos
                      if (loaded.allPlants.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateView(
                            icon: Icons.eco_outlined,
                            title: 'Aún no tienes plantas',
                            subtitle: 'Escanea tu primera planta y aparecerá en esta lista.',
                            onRetry: () => context.go('/scan'),
                            retryLabel: 'Ir al escáner',
                          ),
                        )
                      else if (plants.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateView(
                            icon: Icons.search_off_rounded,
                            title: 'Sin resultados',
                            subtitle: activeGroup != null
                                ? 'No hay plantas que coincidan en "${activeGroup.name}".'
                                : 'No encontramos plantas con esos filtros.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          sliver: SliverList.separated(
                            itemCount: plants.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final plant = plants[index];
                              final group = loaded.findGroupById(plant.groupId);

                              return _PlantTile(
                                plant: plant,
                                group: group,
                                onTap: () => _openPlantDetail(plant.id),
                                onAssignGroup: () =>
                                    _openAssignGroupSheet(plant, loaded.groups),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          '$label · $count',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.slate,
          ),
        ),
      ),
    );
  }
}

class _PlantTile extends StatelessWidget {
  const _PlantTile({
    required this.plant,
    required this.group,
    required this.onTap,
    required this.onAssignGroup,
  });

  final UserPlantModel plant;
  final PlantGroupModel? group;
  final VoidCallback onTap;
  final VoidCallback onAssignGroup;

  @override
  Widget build(BuildContext context) {
    final statusColor = HealthStatusColors.fromHex(plant.healthStatusColor);
    final imageUrl = plant.primaryImageUrl?.trim() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Foto o ícono
            Container(
              width: 62,
              height: 62,
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
                      ),
                    )
                  : const Icon(Icons.eco_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),

            // Datos principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.customName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.anthracite,
                    ),
                  ),
                  if (plant.scientificName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.slateLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Estado de salud
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              plant.healthStatusLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Etiqueta del grupo asignado
                      if (group != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                group!.icon,
                                size: 10,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                group!.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Botón para asignar/mover de grupo
            IconButton(
              tooltip: 'Asignar grupo',
              onPressed: onAssignGroup,
              icon: const Icon(
                Icons.drive_file_move_outline,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slateLight,
            ),
          ],
        ),
      ),
    );
  }
}
