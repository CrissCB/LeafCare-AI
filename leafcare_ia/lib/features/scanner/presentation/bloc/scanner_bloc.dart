import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:leafcare_ia/features/scanner/data/models/scanner_models.dart';

// --- EVENTOS ---
abstract class ScannerEvent {}

class ScannerInitialized extends ScannerEvent {
  ScannerInitialized([this.args]);
  final ScannerRouteArgs? args;
}

class ScannerModeChanged extends ScannerEvent {
  ScannerModeChanged(this.mode);
  final ScanMode mode;
}

class ScannerGroupSelected extends ScannerEvent {
  ScannerGroupSelected(this.group);
  final ScanGroupOption group;
}

class ScannerPlantSelected extends ScannerEvent {
  ScannerPlantSelected(this.plant);
  final ScanPlantOption plant;
}

class ScannerImageCaptured extends ScannerEvent {
  ScannerImageCaptured(this.imagePath);
  final String imagePath;
}

class ScannerSaveNewPlantRequested extends ScannerEvent {
  ScannerSaveNewPlantRequested(this.customName);
  final String customName;
}

class ScannerResetResultRequested extends ScannerEvent {}

// --- ESTADO ---
class ScannerState {
  const ScannerState({
    this.mode = ScanMode.newRegistration,
    this.loadingInitial = false,
    this.loadingPlants = false,
    this.analyzing = false,
    this.saving = false,
    this.groups = const [],
    this.selectedGroup,
    this.groupPlants = const [],
    this.selectedPlant,
    this.analysisResult,
    this.errorMessage,
    this.isLowConfidenceError = false,
    this.successMessage,
  });

  final ScanMode mode;
  final bool loadingInitial;
  final bool loadingPlants;
  final bool analyzing;
  final bool saving;

  final List<ScanGroupOption> groups;
  final ScanGroupOption? selectedGroup;
  final List<ScanPlantOption> groupPlants;
  final ScanPlantOption? selectedPlant;

  final ScanAnalysisResult? analysisResult;
  final String? errorMessage;
  final bool isLowConfidenceError;
  final String? successMessage;

  /// Regla de negocio: sin grupo (y sin planta en Modalidad B) no se puede escanear.
  bool get canCaptureOrPickImage {
    if (analyzing || saving || loadingInitial) return false;
    if (selectedGroup == null) return false;
    if (mode == ScanMode.healthDiagnosis && selectedPlant == null) {
      return false;
    }
    return true;
  }

  ScannerState copyWith({
    ScanMode? mode,
    bool? loadingInitial,
    bool? loadingPlants,
    bool? analyzing,
    bool? saving,
    List<ScanGroupOption>? groups,
    ScanGroupOption? selectedGroup,
    bool clearSelectedGroup = false,
    List<ScanPlantOption>? groupPlants,
    ScanPlantOption? selectedPlant,
    bool clearSelectedPlant = false,
    ScanAnalysisResult? analysisResult,
    bool clearAnalysisResult = false,
    String? errorMessage,
    bool clearError = false,
    bool? isLowConfidenceError,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return ScannerState(
      mode: mode ?? this.mode,
      loadingInitial: loadingInitial ?? this.loadingInitial,
      loadingPlants: loadingPlants ?? this.loadingPlants,
      analyzing: analyzing ?? this.analyzing,
      saving: saving ?? this.saving,
      groups: groups ?? this.groups,
      selectedGroup: clearSelectedGroup
          ? null
          : (selectedGroup ?? this.selectedGroup),
      groupPlants: groupPlants ?? this.groupPlants,
      selectedPlant: clearSelectedPlant
          ? null
          : (selectedPlant ?? this.selectedPlant),
      analysisResult: clearAnalysisResult
          ? null
          : (analysisResult ?? this.analysisResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLowConfidenceError: isLowConfidenceError ?? false,
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

// --- BLOC ---
class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc({required this.datasource}) : super(const ScannerState()) {
    on<ScannerInitialized>(_onInitialized);
    on<ScannerModeChanged>(_onModeChanged);
    on<ScannerGroupSelected>(_onGroupSelected);
    on<ScannerPlantSelected>(_onPlantSelected);
    on<ScannerImageCaptured>(_onImageCaptured);
    on<ScannerSaveNewPlantRequested>(_onSaveNewPlant);
    on<ScannerResetResultRequested>(_onResetResult);
  }

  final ScannerRemoteDatasource datasource;

  Future<void> _onInitialized(
    ScannerInitialized event,
    Emitter<ScannerState> emit,
  ) async {
    final args = event.args;
    emit(
      state.copyWith(
        loadingInitial: true,
        mode: args?.initialMode ?? ScanMode.newRegistration,
        clearError: true,
      ),
    );

    try {
      final groups = await datasource.fetchUserGroups();

      ScanGroupOption? preselectedGroup;
      if (args?.initialGroupId != null) {
        for (final g in groups) {
          if (g.id == args!.initialGroupId) {
            preselectedGroup = g;
            break;
          }
        }
      }

      List<ScanPlantOption> plants = const [];
      ScanPlantOption? preselectedPlant;

      if (preselectedGroup != null &&
          (args?.initialMode ?? state.mode) == ScanMode.healthDiagnosis) {
        plants = await datasource.fetchPlantsByGroup(preselectedGroup.id);
        if (args?.initialPlantId != null) {
          for (final p in plants) {
            if (p.id == args!.initialPlantId) {
              preselectedPlant = p;
              break;
            }
          }
        }
      }

      emit(
        state.copyWith(
          loadingInitial: false,
          groups: groups,
          selectedGroup: preselectedGroup,
          groupPlants: plants,
          selectedPlant: preselectedPlant,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadingInitial: false,
          errorMessage: 'No se pudieron cargar tus grupos de plantas.',
        ),
      );
    }
  }

  Future<void> _onModeChanged(
    ScannerModeChanged event,
    Emitter<ScannerState> emit,
  ) async {
    if (event.mode == state.mode) return;

    emit(
      state.copyWith(
        mode: event.mode,
        clearSelectedPlant: true,
        clearAnalysisResult: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    if (event.mode == ScanMode.healthDiagnosis && state.selectedGroup != null) {
      await _loadPlantsForGroup(state.selectedGroup!.id, emit);
    }
  }

  Future<void> _onGroupSelected(
    ScannerGroupSelected event,
    Emitter<ScannerState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedGroup: event.group,
        clearSelectedPlant: true,
        groupPlants: const [],
        clearAnalysisResult: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    if (state.mode == ScanMode.healthDiagnosis) {
      await _loadPlantsForGroup(event.group.id, emit);
    }
  }

  Future<void> _loadPlantsForGroup(
    String groupId,
    Emitter<ScannerState> emit,
  ) async {
    emit(state.copyWith(loadingPlants: true));
    try {
      final plants = await datasource.fetchPlantsByGroup(groupId);
      emit(state.copyWith(loadingPlants: false, groupPlants: plants));
    } catch (_) {
      emit(
        state.copyWith(
          loadingPlants: false,
          errorMessage: 'No se pudieron cargar las plantas de este grupo.',
        ),
      );
    }
  }

  void _onPlantSelected(
    ScannerPlantSelected event,
    Emitter<ScannerState> emit,
  ) {
    emit(
      state.copyWith(
        selectedPlant: event.plant,
        clearAnalysisResult: true,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  Future<void> _onImageCaptured(
    ScannerImageCaptured event,
    Emitter<ScannerState> emit,
  ) async {
    final group = state.selectedGroup;
    if (group == null) {
      emit(
        state.copyWith(
          errorMessage: 'Selecciona un grupo antes de escanear la planta.',
        ),
      );
      return;
    }

    if (state.mode == ScanMode.healthDiagnosis && state.selectedPlant == null) {
      emit(
        state.copyWith(
          errorMessage:
              'Selecciona la planta del grupo que deseas diagnosticar.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        analyzing: true,
        clearAnalysisResult: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final result = await datasource.analyzeImage(
        mode: state.mode,
        imagePath: event.imagePath,
        group: group,
        existingPlant: state.selectedPlant,
      );

      // En Modalidad B (Diagnóstico de Salud) se guarda automáticamente el historial y la alerta IA
      if (state.mode == ScanMode.healthDiagnosis) {
        await datasource.saveHealthDiagnosis(result: result);
        emit(
          state.copyWith(
            analyzing: false,
            analysisResult: result,
            successMessage:
                'Diagnóstico guardado y alerta IA generada correctamente.',
          ),
        );
        return;
      }

      // En Modalidad A espera confirmación con botones "Guardar" o "Cancelar"
      emit(state.copyWith(analyzing: false, analysisResult: result));
    } on ScannerException catch (e) {
      emit(
        state.copyWith(
          analyzing: false,
          errorMessage: e.message,
          isLowConfidenceError: e.isLowConfidence,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          analyzing: false,
          errorMessage: 'Ocurrió un error inesperado al analizar la imagen. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> _onSaveNewPlant(
    ScannerSaveNewPlantRequested event,
    Emitter<ScannerState> emit,
  ) async {
    final result = state.analysisResult;
    if (result == null || state.saving) return;

    emit(state.copyWith(saving: true, clearError: true));
    try {
      await datasource.saveNewPlantRegistration(
        result: result,
        customName: event.customName,
      );
      emit(
        state.copyWith(
          saving: false,
          clearAnalysisResult: true,
          successMessage: 'Planta registrada en "${result.groupName}".',
        ),
      );
    } on ScannerException catch (e) {
      emit(state.copyWith(saving: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          saving: false,
          errorMessage: 'No se pudo guardar la planta en tu jardín.',
        ),
      );
    }
  }

  void _onResetResult(
    ScannerResetResultRequested event,
    Emitter<ScannerState> emit,
  ) {
    emit(
      state.copyWith(
        clearAnalysisResult: true,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }
}
