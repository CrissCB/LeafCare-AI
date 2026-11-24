import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/features/stats/data/models/stats_summary_model.dart';
import 'package:leafcare_ia/features/stats/data/repositories/stats_repository.dart';

// --- Eventos ---
sealed class StatsEvent {
  const StatsEvent();
}

class LoadStatsRequested extends StatsEvent {
  const LoadStatsRequested();
}

class RefreshStatsRequested extends StatsEvent {
  const RefreshStatsRequested();
}

// --- Estados ---
sealed class StatsState {
  const StatsState();
}

class StatsInitial extends StatsState {
  const StatsInitial();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsLoaded extends StatsState {
  const StatsLoaded(this.summary);

  final StatsSummaryModel summary;
}

class StatsError extends StatsState {
  const StatsError(this.message);

  final String message;
}

// --- BLoC ---
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc({required StatsRepository repository})
    : _repository = repository,
      super(const StatsInitial()) {
    on<LoadStatsRequested>(_onLoad);
    on<RefreshStatsRequested>(_onRefresh);
  }

  final StatsRepository _repository;

  Future<void> _onLoad(
    LoadStatsRequested event,
    Emitter<StatsState> emit,
  ) async {
    emit(const StatsLoading());
    try {
      final summary = await _repository.getStatsSummary();
      emit(StatsLoaded(summary));
    } catch (_) {
      emit(const StatsError('No se pudieron cargar las estadísticas.'));
    }
  }

  Future<void> _onRefresh(
    RefreshStatsRequested event,
    Emitter<StatsState> emit,
  ) async {
    try {
      final summary = await _repository.getStatsSummary();
      emit(StatsLoaded(summary));
    } catch (_) {
      if (state is! StatsLoaded) {
        emit(const StatsError('No se pudieron actualizar las estadísticas.'));
      }
    }
  }
}
