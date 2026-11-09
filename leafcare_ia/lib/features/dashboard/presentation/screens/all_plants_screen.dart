import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';
import 'package:leafcare_ia/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';

/// Pantalla "Todas las plantas": lista completa con buscador.
class AllPlantsScreen extends StatefulWidget {
  const AllPlantsScreen({super.key});

  @override
  State<AllPlantsScreen> createState() => _AllPlantsScreenState();
}

/// Orden en el que se muestran las plantas.
enum _PlantSort { recent, name, health }

class _AllPlantsScreenState extends State<AllPlantsScreen> {
  final DashboardDatasource _datasource = DashboardDatasource();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<UserPlantModel>> _plantsFuture;
  String _query = '';
  String? _healthFilter;
  _PlantSort _sort = _PlantSort.recent;

  @override
  void initState() {
    super.initState();
    _plantsFuture = _datasource.fetchPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _plantsFuture = _datasource.fetchPlants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const SubPageHeader(
            title: 'Todas las plantas',
            subtitle: 'Toca una planta para ver su detalle y su historial.',
            icon: Icons.local_florist_rounded,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    return FutureBuilder<List<UserPlantModel>>(
      future: _plantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return EmptyStateView(
            icon: Icons.wifi_off_rounded,
            title: 'No se pudieron cargar tus plantas',
            subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
            onRetry: _reload,
          );
        }

        final all = snapshot.data!;
        final plants = _filter(all);
        final healthLabels = _healthLabels(all);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _reload();
            await _plantsFuture;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Buscador
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filtros por estado de salud
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
                                  label: 'Todas',
                                  count: all.length,
                                  selected: _healthFilter == null,
                                  onTap: () =>
                                      setState(() => _healthFilter = null),
                                );
                              }

                              final label = healthLabels[index - 1];
                              final count = all
                                  .where((plant) => plant.healthLabel == label)
                                  .length;

                              return _FilterPill(
                                label: label,
                                count: count,
                                selected: _healthFilter == label,
                                onTap: () => setState(() {
                                  _healthFilter = _healthFilter == label
                                      ? null
                                      : label;
                                }),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Text(
                            all.isEmpty
                                ? 'Todavía no tienes plantas'
                                : '${plants.length} de ${all.length} plantas',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.slateLight,
                            ),
                          ),
                          const Spacer(),
                          // Menú para ordenar la lista
                          PopupMenuButton<_PlantSort>(
                            initialValue: _sort,
                            tooltip: 'Ordenar plantas',
                            onSelected: (value) =>
                                setState(() => _sort = value),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: _PlantSort.recent,
                                child: Text('Más recientes'),
                              ),
                              PopupMenuItem(
                                value: _PlantSort.name,
                                child: Text('Nombre (A-Z)'),
                              ),
                              PopupMenuItem(
                                value: _PlantSort.health,
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
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.border),
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
                                    _sortLabel,
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
              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.eco_outlined,
                    title: 'Aún no tienes plantas',
                    subtitle:
                        'Escanea tu primera planta y aparecerá en esta lista.',
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
                    subtitle: _healthFilter != null
                        ? 'No hay plantas con el estado "$_healthFilter". Prueba con otro filtro.'
                        : 'No encontramos plantas con ese nombre. Prueba con otra palabra.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: plants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final plant = plants[index];
                      return _PlantTile(
                        plant: plant,
                        onTap: () => context.push('/plant/${plant.id}'),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Filtra por nombre y por estado de salud, y luego ordena la lista.
  List<UserPlantModel> _filter(List<UserPlantModel> plants) {
    final query = _query.trim().toLowerCase();

    final result = plants.where((plant) {
      final matchesQuery =
          query.isEmpty ||
          plant.customName.toLowerCase().contains(query) ||
          plant.scientificName.toLowerCase().contains(query) ||
          plant.commonName.toLowerCase().contains(query);

      final matchesHealth =
          _healthFilter == null || plant.healthLabel == _healthFilter;

      return matchesQuery && matchesHealth;
    }).toList();

    switch (_sort) {
      case _PlantSort.recent:
        // Ya vienen de la más nueva a la más antigua.
        break;
      case _PlantSort.name:
        result.sort(
          (a, b) =>
              a.customName.toLowerCase().compareTo(b.customName.toLowerCase()),
        );
      case _PlantSort.health:
        result.sort((a, b) {
          final byHealth = _healthRank(
            a.healthLabel,
          ).compareTo(_healthRank(b.healthLabel));
          if (byHealth != 0) return byHealth;
          return a.customName.toLowerCase().compareTo(
            b.customName.toLowerCase(),
          );
        });
    }

    return result;
  }

  /// Devuelve las etiquetas de salud que existen en las plantas.
  List<String> _healthLabels(List<UserPlantModel> plants) {
    final labels = <String>{};
    for (final plant in plants) {
      labels.add(plant.healthLabel);
    }
    return labels.toList();
  }

  /// Mientras más bajo el número, más urgente es el estado.
  int _healthRank(String label) {
    final text = label.toLowerCase();
    if (text.contains('salud')) return 2;
    if (text.contains('aten') ||
        text.contains('riesgo') ||
        text.contains('urgente')) {
      return 1;
    }
    return 0;
  }

  /// Texto corto del orden elegido.
  String get _sortLabel {
    switch (_sort) {
      case _PlantSort.recent:
        return 'Recientes';
      case _PlantSort.name:
        return 'Nombre';
      case _PlantSort.health:
        return 'Estado';
    }
  }
}

/// Botón redondeado para filtrar las plantas por estado.
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

/// Fila con la foto, el nombre y el estado de una planta.
class _PlantTile extends StatelessWidget {
  const _PlantTile({required this.plant, required this.onTap});

  final UserPlantModel plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _colorFromHex(plant.healthColorHex);

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
              child: plant.imageUrl.isNotEmpty
                  ? Image.network(
                      plant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.eco_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
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
                          plant.healthLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  Color _colorFromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? AppColors.slate : Color(parsed);
  }
}
