import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';

import 'package:leafcare_ia/features/plant_detail/data/datasources/plant_remote_datasource.dart';
import 'package:leafcare_ia/features/plant_detail/data/repositories/plant_repository.dart';
import 'package:leafcare_ia/features/plant_detail/presentation/bloc/plant_detail_bloc.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/plant_detail_model.dart';
import 'package:leafcare_ia/features/plant_detail/presentation/widgets/plant_care_card.dart';
import 'package:leafcare_ia/features/plant_detail/presentation/widgets/plant_detail_hero.dart';
import 'package:leafcare_ia/features/plant_detail/presentation/widgets/plant_health_timeline.dart';
import 'package:leafcare_ia/features/plant_detail/presentation/widgets/plant_info_card.dart';
import 'package:leafcare_ia/features/plant_detail/presentation/widgets/edit_plant_dialog.dart';

class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlantDetailBloc(
        repository: const PlantRepository(datasource: PlantRemoteDatasource()),
      )..add(LoadPlantDetail(plantId)),
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: BlocConsumer<PlantDetailBloc, PlantDetailState>(
          listener: (context, state) {
            if (state is PlantDetailDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Planta eliminada correctamente'),
                  backgroundColor: AppColors.primary,
                ),
              );
              context.pop(true);
            }

            if (state is PlantDetailLoaded && state.feedbackMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.feedbackMessage!),
                  backgroundColor: state.isFeedbackError
                      ? AppColors.error
                      : AppColors.primary,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PlantDetailLoading || state is PlantDetailDeleted) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is PlantDetailError) {
              return EmptyStateView(
                icon: Icons.eco_outlined,
                title: 'No se pudo cargar la planta',
                subtitle: state.message,
                onRetry: () => context.read<PlantDetailBloc>().add(
                  LoadPlantDetail(plantId),
                ),
              );
            }

            final loadedState = state as PlantDetailLoaded;
            final plant = loadedState.plant;

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          context.read<PlantDetailBloc>().add(
                            RefreshPlantDetail(plantId),
                          );
                          await context
                              .read<PlantDetailBloc>()
                              .stream
                              .firstWhere(
                                (s) =>
                                    s is PlantDetailLoaded ||
                                    s is PlantDetailError,
                              );
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              PlantDetailHero(
                                plant: plant,
                                onMoreOptions: () =>
                                    _showOptionsSheet(context, plant),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  24,
                                ),
                                child: Column(
                                  children: [
                                    PlantInfoCard(plant: plant),
                                    const SizedBox(height: 16),
                                    PlantCareCard(plant: plant),
                                    const SizedBox(height: 20),
                                    PlantHealthTimeline(
                                      scans: plant.scanHistory,
                                      fallbackImageUrl: plant.primaryImageUrl,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Botón fijo inferior: Nuevo diagnóstico IA
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/scan'),
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.neon,
                              size: 20,
                            ),
                            label: Text(
                              'Nuevo diagnóstico IA',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (loadedState.isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext parentContext, PlantDetailModel plant) {
    showModalBottomSheet<void>(
      context: parentContext,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Editar nombre o grupo',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showEditDialog(parentContext, plant);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Eliminar planta',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDeleteDialog(parentContext, plant);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext parentContext, PlantDetailModel plant) {
    showDialog<void>(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Eliminar planta?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.anthracite,
          ),
        ),
        content: Text(
          'Estás a punto de eliminar a "${plant.customName}". Esta acción borrará todo su historial de escaneos y no se puede deshacer.',
          style: GoogleFonts.inter(color: AppColors.slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppColors.slate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              parentContext.read<PlantDetailBloc>().add(DeletePlant(plant.id));
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext parentContext, PlantDetailModel plant) {
    showDialog<void>(
      context: parentContext,
      builder: (_) => EditPlantDialog(
        plant: plant,
        onSave: (newName, newGroupId) {
          parentContext.read<PlantDetailBloc>().add(
            UpdatePlantDetail(
              plantId: plant.id,
              customName: newName,
              groupId: newGroupId,
            ),
          );
        },
      ),
    );
  }
}
