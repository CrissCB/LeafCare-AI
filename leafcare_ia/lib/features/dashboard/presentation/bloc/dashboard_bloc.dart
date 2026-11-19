import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_profile_model.dart';
import 'package:leafcare_ia/features/dashboard/data/repositories/dashboard_repository.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}

class CompleteReminder extends DashboardEvent {
  const CompleteReminder(this.reminderId);

  final String reminderId;
}

sealed class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.summary,
    this.completingReminderIds = const {},
    this.notice,
    this.noticeIsError = false,
  });

  final DashboardSummaryModel summary;
  final Set<String> completingReminderIds;
  final String? notice;
  final bool noticeIsError;

  UserProfileModel get profile => summary.profile;
  String get userName => summary.profile.name;
  String? get avatarUrl => summary.profile.avatarUrl;
  int get totalPlantsCount => summary.totalPlantsCount;
  int get unreadAlertsCount => summary.unreadAlertsCount;
  bool get hasUnreadAlerts => summary.hasUnreadAlerts;
  List<UserPlantModel> get topPlants => summary.topPlants;
  List<CareReminderModel> get todayReminders => summary.todayReminders;
  String get dailyTip => summary.dailyTip;

  DashboardLoaded copyWith({
    DashboardSummaryModel? summary,
    Set<String>? completingReminderIds,
    String? notice,
    bool noticeIsError = false,
    bool clearNotice = false,
  }) {
    return DashboardLoaded(
      summary: summary ?? this.summary,
      completingReminderIds:
          completingReminderIds ?? this.completingReminderIds,
      notice: clearNotice ? null : notice,
      noticeIsError: clearNotice ? false : noticeIsError,
    );
  }
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    DashboardRepository? repository,
    Future<void> Function(String reminderId)? onCompleteReminder,
  }) : _repository =
           repository ??
           DashboardRepository(
             datasource: DashboardDatasource(
               supabaseClient: const AppSupabaseClient(),
             ),
           ),
       _onCompleteReminderAction =
           onCompleteReminder ?? _defaultCompleteReminder,
       super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onRefresh);
    on<CompleteReminder>(_onCompleteReminder);
  }

  final DashboardRepository _repository;
  final Future<void> Function(String reminderId) _onCompleteReminderAction;

  /// Punto temporal hasta inyectar `alertsRepository.completeReminder`.
  static Future<void> _defaultCompleteReminder(String reminderId) async {
    const supabase = AppSupabaseClient();
    final userId = supabase.currentUserId;
    if (userId == null) return;

    await supabase.client
        .from('care_reminders')
        .update({'is_completed': true})
        .eq('id', reminderId)
        .eq('user_id', userId);
  }

  Future<void> _onLoad(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _fetchSummary(emit, isRefresh: false);
  }

  Future<void> _onRefresh(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    final hasLoadedData = state is DashboardLoaded;
    if (!hasLoadedData) {
      emit(const DashboardLoading());
    }
    await _fetchSummary(emit, isRefresh: hasLoadedData);
  }

  Future<void> _onCompleteReminder(
    CompleteReminder event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state;
    if (current is! DashboardLoaded) return;
    if (current.completingReminderIds.contains(event.reminderId)) return;

    emit(
      current.copyWith(
        completingReminderIds: {
          ...current.completingReminderIds,
          event.reminderId,
        },
        clearNotice: true,
      ),
    );

    try {
      await _onCompleteReminderAction(event.reminderId);
      final summary = await _repository.loadDashboardSummary();

      emit(
        DashboardLoaded(
          summary: summary,
          notice: 'Recordatorio marcado como hecho',
        ),
      );
    } catch (_) {
      final latest = state is DashboardLoaded
          ? state as DashboardLoaded
          : current;
      final remaining = {...latest.completingReminderIds}
        ..remove(event.reminderId);

      emit(
        latest.copyWith(
          completingReminderIds: remaining,
          notice: 'No se pudo completar el recordatorio',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _fetchSummary(
    Emitter<DashboardState> emit, {
    required bool isRefresh,
  }) async {
    try {
      final summary = await _repository.loadDashboardSummary();
      emit(DashboardLoaded(summary: summary));
    } on PostgrestException {
      _handleFailure(
        emit,
        isRefresh: isRefresh,
        message: 'Error al consultar tus datos en el servidor.',
      );
    } catch (_) {
      _handleFailure(
        emit,
        isRefresh: isRefresh,
        message: 'No se pudieron cargar tus datos. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  void _handleFailure(
    Emitter<DashboardState> emit, {
    required bool isRefresh,
    required String message,
  }) {
    final current = state;
    if (isRefresh && current is DashboardLoaded) {
      emit(current.copyWith(notice: message, noticeIsError: true));
    } else {
      emit(DashboardError(message));
    }
  }
}
