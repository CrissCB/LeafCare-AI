import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/features/plant_detail/data/models/plant_detail_model.dart';
import 'package:leafcare_ia/features/plant_detail/data/repositories/plant_repository.dart';

// ─────────────────────────────────────────────
// EVENTOS
// ─────────────────────────────────────────────
abstract class PlantDetailEvent {}

class LoadPlantDetail extends PlantDetailEvent {
  LoadPlantDetail(this.plantId);
  final String plantId;
}

class RefreshPlantDetail extends PlantDetailEvent {
  RefreshPlantDetail(this.plantId);
  final String plantId;
}

class UpdatePlantDetail extends PlantDetailEvent {
  UpdatePlantDetail({
    required this.plantId,
    required this.customName,
    this.groupId,
  });

  final String plantId;
  final String customName;
  final String? groupId;
}

class DeletePlant extends PlantDetailEvent {
  DeletePlant(this.plantId);
  final String plantId;
}

// ─────────────────────────────────────────────
// ESTADOS
// ─────────────────────────────────────────────
abstract class PlantDetailState {}

class PlantDetailLoading extends PlantDetailState {}

class PlantDetailLoaded extends PlantDetailState {
  PlantDetailLoaded(
    this.plant, {
    this.isProcessing = false,
    this.feedbackMessage,
    this.isFeedbackError = false,
  });

  final PlantDetailModel plant;
  final bool isProcessing;
  final String? feedbackMessage;
  final bool isFeedbackError;
}

class PlantDetailDeleted extends PlantDetailState {}

class PlantDetailError extends PlantDetailState {
  PlantDetailError(this.message);
  final String message;
}

// ─────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────
class PlantDetailBloc extends Bloc<PlantDetailEvent, PlantDetailState> {
  PlantDetailBloc({required this.repository}) : super(PlantDetailLoading()) {
    on<LoadPlantDetail>(_onLoad);
    on<RefreshPlantDetail>(_onRefresh);
    on<UpdatePlantDetail>(_onUpdate);
    on<DeletePlant>(_onDelete);
  }

  final PlantRepository repository;

  Future<void> _onLoad(
    LoadPlantDetail event,
    Emitter<PlantDetailState> emit,
  ) async {
    emit(PlantDetailLoading());
    try {
      final plant = await repository.getFullPlantProfile(event.plantId);
      emit(PlantDetailLoaded(plant));
    } catch (e) {
      emit(PlantDetailError('No se pudo cargar la información de la planta.'));
    }
  }

  Future<void> _onRefresh(
    RefreshPlantDetail event,
    Emitter<PlantDetailState> emit,
  ) async {
    try {
      final plant = await repository.getFullPlantProfile(event.plantId);
      emit(PlantDetailLoaded(plant));
    } catch (_) {
      emit(PlantDetailError('No se pudo actualizar la información.'));
    }
  }

  Future<void> _onUpdate(
    UpdatePlantDetail event,
    Emitter<PlantDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PlantDetailLoaded) return;

    emit(PlantDetailLoaded(currentState.plant, isProcessing: true));

    try {
      await repository.updatePlant(
        plantId: event.plantId,
        customName: event.customName,
        groupId: event.groupId,
      );
      final updatedPlant = await repository.getFullPlantProfile(event.plantId);
      emit(
        PlantDetailLoaded(
          updatedPlant,
          feedbackMessage: 'Planta actualizada correctamente',
        ),
      );
    } catch (_) {
      emit(
        PlantDetailLoaded(
          currentState.plant,
          feedbackMessage: 'Error al guardar los cambios',
          isFeedbackError: true,
        ),
      );
    }
  }

  Future<void> _onDelete(
    DeletePlant event,
    Emitter<PlantDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PlantDetailLoaded) return;

    emit(PlantDetailLoaded(currentState.plant, isProcessing: true));

    try {
      await repository.deletePlant(event.plantId);
      emit(PlantDetailDeleted());
    } catch (_) {
      emit(
        PlantDetailLoaded(
          currentState.plant,
          feedbackMessage: 'No se pudo eliminar la planta',
          isFeedbackError: true,
        ),
      );
    }
  }
}
