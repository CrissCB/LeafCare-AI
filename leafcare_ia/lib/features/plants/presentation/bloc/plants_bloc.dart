import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/plants/data/datasources/plants_datasource.dart';
import 'package:leafcare_ia/features/plants/data/models/plant_group_model.dart';
import 'package:leafcare_ia/features/plants/data/repositories/plants_repository.dart';

enum PlantSort { recent, name, health }

// --- EVENTOS ---

sealed class PlantsEvent {
  const PlantsEvent();
}

class LoadPlants extends PlantsEvent {
  const LoadPlants();
}

class RefreshPlants extends PlantsEvent {
  const RefreshPlants();
}

class SearchPlantsChanged extends PlantsEvent {
  const SearchPlantsChanged(this.query);

  final String query;
}

class SelectPlantGroup extends PlantsEvent {
  const SelectPlantGroup(this.groupId);

  /// `null` representa "Todas las plantas".
  final String? groupId;
}

class SelectHealthFilter extends PlantsEvent {
  const SelectHealthFilter(this.healthLabel);

  final String? healthLabel;
}

class ChangePlantSort extends PlantsEvent {
  const ChangePlantSort(this.sort);

  final PlantSort sort;
}

class CreatePlantGroup extends PlantsEvent {
  const CreatePlantGroup({required this.name, required this.iconName});

  final String name;
  final String iconName;
}

class UpdatePlantGroup extends PlantsEvent {
  const UpdatePlantGroup({
    required this.groupId,
    required this.name,
    required this.iconName,
  });

  final String groupId;
  final String name;
  final String iconName;
}

class DeletePlantGroup extends PlantsEvent {
  const DeletePlantGroup(this.groupId);

  final String groupId;
}

class AssignPlantGroup extends PlantsEvent {
  const AssignPlantGroup({required this.plantId, this.groupId});

  final String plantId;
  final String? groupId;
}

// --- ESTADOS ---

sealed class PlantsState {
  const PlantsState();
}

class PlantsInitial extends PlantsState {
  const PlantsInitial();
}

class PlantsLoading extends PlantsState {
  const PlantsLoading();
}

class PlantsError extends PlantsState {
  const PlantsError(this.message);

  final String message;
}

class PlantsLoaded extends PlantsState {
  const PlantsLoaded({
    required this.allPlants,
    required this.groups,
    this.searchQuery = '',
    this.selectedGroupId,
    this.selectedHealthFilter,
    this.sort = PlantSort.recent,
    this.isSubmitting = false,
    this.notice,
    this.noticeIsError = false,
  });

  final List<UserPlantModel> allPlants;
  final List<PlantGroupModel> groups;
  final String searchQuery;
  final String? selectedGroupId;
  final String? selectedHealthFilter;
  final PlantSort sort;
  final bool isSubmitting;
  final String? notice;
  final bool noticeIsError;

  /// Plantas pertenecientes al grupo seleccionado (o todas si `selectedGroupId == null`).
  List<UserPlantModel> get plantsInSelectedGroup {
    if (selectedGroupId == null) return allPlants;
    return allPlants
        .where((plant) => plant.groupId == selectedGroupId)
        .toList(growable: false);
  }

  /// Etiquetas únicas de estado de salud disponibles dentro del grupo actual.
  List<String> get availableHealthLabels {
    final labels = <String>{};
    for (final plant in plantsInSelectedGroup) {
      if (plant.healthStatusLabel.trim().isNotEmpty) {
        labels.add(plant.healthStatusLabel.trim());
      }
    }
    return labels.toList(growable: false);
  }

  /// Lista final tras aplicar grupo, búsqueda por texto, estado de salud y orden.
  List<UserPlantModel> get filteredPlants {
    final query = searchQuery.trim().toLowerCase();

    final result = plantsInSelectedGroup.where((plant) {
      final matchesQuery =
          query.isEmpty ||
          plant.customName.toLowerCase().contains(query) ||
          plant.scientificName.toLowerCase().contains(query) ||
          plant.commonName.toLowerCase().contains(query);

      final matchesHealth =
          selectedHealthFilter == null ||
          plant.healthStatusLabel == selectedHealthFilter;

      return matchesQuery && matchesHealth;
    }).toList();

    switch (sort) {
      case PlantSort.recent:
        break;
      case PlantSort.name:
        result.sort(
          (a, b) =>
              a.customName.toLowerCase().compareTo(b.customName.toLowerCase()),
        );
      case PlantSort.health:
        result.sort((a, b) {
          final byHealth = _healthRank(a.healthStatusLabel)
              .compareTo(_healthRank(b.healthStatusLabel));
          if (byHealth != 0) return byHealth;
          return a.customName.toLowerCase().compareTo(
            b.customName.toLowerCase(),
          );
        });
    }

    return result;
  }

  int countPlantsInGroup(String groupId) {
    return allPlants.where((p) => p.groupId == groupId).length;
  }

  PlantGroupModel? findGroupById(String? groupId) {
    if (groupId == null) return null;
    for (final group in groups) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  static int _healthRank(String label) {
    final text = label.toLowerCase();
    if (text.contains('salud')) return 2;
    if (text.contains('aten') ||
        text.contains('riesgo') ||
        text.contains('urgente')) {
      return 1;
    }
    return 0;
  }

  PlantsLoaded copyWith({
    List<UserPlantModel>? allPlants,
    List<PlantGroupModel>? groups,
    String? searchQuery,
    String? selectedGroupId,
    bool clearSelectedGroup = false,
    String? selectedHealthFilter,
    bool clearHealthFilter = false,
    PlantSort? sort,
    bool? isSubmitting,
    String? notice,
    bool noticeIsError = false,
    bool clearNotice = false,
  }) {
    return PlantsLoaded(
      allPlants: allPlants ?? this.allPlants,
      groups: groups ?? this.groups,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGroupId: clearSelectedGroup
          ? null
          : (selectedGroupId ?? this.selectedGroupId),
      selectedHealthFilter: clearHealthFilter
          ? null
          : (selectedHealthFilter ?? this.selectedHealthFilter),
      sort: sort ?? this.sort,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      notice: clearNotice ? null : notice,
      noticeIsError: clearNotice ? false : noticeIsError,
    );
  }
}

// --- BLOC ---

class PlantsBloc extends Bloc<PlantsEvent, PlantsState> {
  PlantsBloc({PlantsRepository? repository})
    : _repository =
          repository ??
          PlantsRepository(
            datasource: PlantsDatasource(
              supabaseClient: const AppSupabaseClient(),
            ),
          ),
      super(const PlantsInitial()) {
    on<LoadPlants>(_onLoad);
    on<RefreshPlants>(_onRefresh);
    on<SearchPlantsChanged>(_onSearchChanged);
    on<SelectPlantGroup>(_onSelectGroup);
    on<SelectHealthFilter>(_onSelectHealthFilter);
    on<ChangePlantSort>(_onChangeSort);
    on<CreatePlantGroup>(_onCreateGroup);
    on<UpdatePlantGroup>(_onUpdateGroup);
    on<DeletePlantGroup>(_onDeleteGroup);
    on<AssignPlantGroup>(_onAssignPlantGroup);
  }

  final PlantsRepository _repository;

  Future<void> _onLoad(LoadPlants event, Emitter<PlantsState> emit) async {
    emit(const PlantsLoading());
    await _fetchData(emit, isRefresh: false);
  }

  Future<void> _onRefresh(
    RefreshPlants event,
    Emitter<PlantsState> emit,
  ) async {
    final hasData = state is PlantsLoaded;
    if (!hasData) {
      emit(const PlantsLoading());
    }
    await _fetchData(emit, isRefresh: hasData);
  }

  void _onSearchChanged(SearchPlantsChanged event, Emitter<PlantsState> emit) {
    final current = state;
    if (current is! PlantsLoaded) return;
    emit(current.copyWith(searchQuery: event.query, clearNotice: true));
  }

  void _onSelectGroup(SelectPlantGroup event, Emitter<PlantsState> emit) {
    final current = state;
    if (current is! PlantsLoaded) return;

    emit(
      current.copyWith(
        selectedGroupId: event.groupId,
        clearSelectedGroup: event.groupId == null,
        clearHealthFilter: true,
        clearNotice: true,
      ),
    );
  }

  void _onSelectHealthFilter(
    SelectHealthFilter event,
    Emitter<PlantsState> emit,
  ) {
    final current = state;
    if (current is! PlantsLoaded) return;

    emit(
      current.copyWith(
        selectedHealthFilter: event.healthLabel,
        clearHealthFilter: event.healthLabel == null,
        clearNotice: true,
      ),
    );
  }

  void _onChangeSort(ChangePlantSort event, Emitter<PlantsState> emit) {
    final current = state;
    if (current is! PlantsLoaded) return;

    emit(current.copyWith(sort: event.sort, clearNotice: true));
  }

  Future<void> _onCreateGroup(
    CreatePlantGroup event,
    Emitter<PlantsState> emit,
  ) async {
    final current = state;
    if (current is! PlantsLoaded || current.isSubmitting) return;

    emit(current.copyWith(isSubmitting: true, clearNotice: true));

    try {
      final created = await _repository.createGroup(
        name: event.name,
        iconName: event.iconName,
      );
      final data = await _repository.loadPlantsAndGroups();

      emit(
        current.copyWith(
          allPlants: data.plants,
          groups: data.groups,
          selectedGroupId: created.id,
          clearHealthFilter: true,
          isSubmitting: false,
          notice: 'Grupo "${created.name}" creado',
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isSubmitting: false,
          notice: 'No se pudo crear el grupo. Inténtalo de nuevo.',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onUpdateGroup(
    UpdatePlantGroup event,
    Emitter<PlantsState> emit,
  ) async {
    final current = state;
    if (current is! PlantsLoaded || current.isSubmitting) return;

    emit(current.copyWith(isSubmitting: true, clearNotice: true));

    try {
      final updated = await _repository.updateGroup(
        groupId: event.groupId,
        name: event.name,
        iconName: event.iconName,
      );
      final data = await _repository.loadPlantsAndGroups();

      emit(
        current.copyWith(
          allPlants: data.plants,
          groups: data.groups,
          isSubmitting: false,
          notice: 'Grupo "${updated.name}" actualizado',
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isSubmitting: false,
          notice: 'No se pudo actualizar el grupo.',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onDeleteGroup(
    DeletePlantGroup event,
    Emitter<PlantsState> emit,
  ) async {
    final current = state;
    if (current is! PlantsLoaded || current.isSubmitting) return;

    emit(current.copyWith(isSubmitting: true, clearNotice: true));

    try {
      await _repository.deleteGroup(event.groupId);
      final data = await _repository.loadPlantsAndGroups();
      final deletedWasSelected = current.selectedGroupId == event.groupId;

      emit(
        current.copyWith(
          allPlants: data.plants,
          groups: data.groups,
          clearSelectedGroup: deletedWasSelected,
          clearHealthFilter: deletedWasSelected,
          isSubmitting: false,
          notice: 'Grupo eliminado',
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isSubmitting: false,
          notice: 'No se pudo eliminar el grupo.',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onAssignPlantGroup(
    AssignPlantGroup event,
    Emitter<PlantsState> emit,
  ) async {
    final current = state;
    if (current is! PlantsLoaded) return;

    try {
      await _repository.assignPlantToGroup(
        plantId: event.plantId,
        groupId: event.groupId,
      );
      final data = await _repository.loadPlantsAndGroups();
      final group = current.findGroupById(event.groupId);

      emit(
        current.copyWith(
          allPlants: data.plants,
          groups: data.groups,
          notice: group != null
              ? 'Planta movida a "${group.name}"'
              : 'Planta quitada del grupo',
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          notice: 'No se pudo cambiar el grupo de la planta.',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _fetchData(
    Emitter<PlantsState> emit, {
    required bool isRefresh,
  }) async {
    try {
      final current = state;
      final data = await _repository.loadPlantsAndGroups();

      if (current is PlantsLoaded) {
        final stillExists =
            current.selectedGroupId == null ||
            data.groups.any((g) => g.id == current.selectedGroupId);

        emit(
          current.copyWith(
            allPlants: data.plants,
            groups: data.groups,
            clearSelectedGroup: !stillExists,
            clearNotice: true,
          ),
        );
      } else {
        emit(PlantsLoaded(allPlants: data.plants, groups: data.groups));
      }
    } on PostgrestException {
      _handleError(emit, isRefresh, 'Error al consultar tus plantas.');
    } catch (_) {
      _handleError(
        emit,
        isRefresh,
        'No se pudieron cargar tus plantas. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  void _handleError(Emitter<PlantsState> emit, bool isRefresh, String message) {
    final current = state;
    if (isRefresh && current is PlantsLoaded) {
      emit(current.copyWith(notice: message, noticeIsError: true));
    } else {
      emit(PlantsError(message));
    }
  }
}
