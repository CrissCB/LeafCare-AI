import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/alerts/data/datasources/alerts_datasource.dart';
import 'package:leafcare_ia/features/alerts/data/models/care_reminder_item_model.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_model.dart';
import 'package:leafcare_ia/features/alerts/data/repositories/alerts_repository.dart';

enum AlertsTab { reminders, iaAlerts }

/// Eventos del Centro de Alertas.
sealed class AlertsEvent {
  const AlertsEvent();
}

class LoadAlertsModule extends AlertsEvent {
  const LoadAlertsModule();
}

class RefreshAlertsModule extends AlertsEvent {
  const RefreshAlertsModule();
}

class AlertsTabChanged extends AlertsEvent {
  const AlertsTabChanged(this.tab);

  final AlertsTab tab;
}

class CreateReminderRequested extends AlertsEvent {
  const CreateReminderRequested({
    required this.plantId,
    required this.treatmentAction,
    required this.iconName,
    required this.scheduledTime,
    required this.isRecurrent,
    this.recurrenceDays,
  });

  final String plantId;
  final String treatmentAction;
  final String iconName;
  final DateTime scheduledTime;
  final bool isRecurrent;
  final int? recurrenceDays;
}

class UpdateReminderRequested extends AlertsEvent {
  const UpdateReminderRequested({
    required this.reminderId,
    required this.treatmentAction,
    required this.iconName,
    required this.scheduledTime,
    required this.isRecurrent,
    this.recurrenceDays,
  });

  final String reminderId;
  final String treatmentAction;
  final String iconName;
  final DateTime scheduledTime;
  final bool isRecurrent;
  final int? recurrenceDays;
}

class CompleteReminderRequested extends AlertsEvent {
  const CompleteReminderRequested(this.reminderId);

  final String reminderId;
}

class SnoozeReminderRequested extends AlertsEvent {
  const SnoozeReminderRequested(this.reminder);

  final CareReminderItemModel reminder;
}

class DeleteReminderRequested extends AlertsEvent {
  const DeleteReminderRequested(this.reminderId);

  final String reminderId;
}

class MarkIaAlertAsReadRequested extends AlertsEvent {
  const MarkIaAlertAsReadRequested(this.alertId);

  final String alertId;
}

class DeleteIaAlertRequested extends AlertsEvent {
  const DeleteIaAlertRequested(this.alertId);

  final String alertId;
}

class RestoreIaAlertRequested extends AlertsEvent {
  const RestoreIaAlertRequested(this.alertId);

  final String alertId;
}

/// Estados del Centro de Alertas.
sealed class AlertsState {
  const AlertsState();
}

class AlertsInitial extends AlertsState {
  const AlertsInitial();
}

class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

class AlertsError extends AlertsState {
  const AlertsError(this.message);

  final String message;
}

class AlertsLoaded extends AlertsState {
  const AlertsLoaded({
    required this.userName,
    this.avatarUrl,
    required this.iaAlerts,
    required this.reminders,
    required this.plantOptions,
    required this.groupOptions,
    this.selectedTab = AlertsTab.reminders,
    this.busyReminderIds = const {},
    this.isSavingForm = false,
    this.notice,
    this.noticeIsError = false,
  });

  final String userName;
  final String? avatarUrl;
  final List<IaAlertModel> iaAlerts;
  final List<CareReminderItemModel> reminders;
  final List<PlantSelectOption> plantOptions;
  final List<GroupFilterOption> groupOptions;
  final AlertsTab selectedTab;
  final Set<String> busyReminderIds;
  final bool isSavingForm;
  final String? notice;
  final bool noticeIsError;

  static DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Recordatorios de HOY (incluye los de hoy + pendientes tardíos de días previos).
  List<CareReminderItemModel> get todayReminders {
    final now = DateTime.now();
    final today = _dayOnly(now);

    final list = reminders.where((r) {
      final day = _dayOnly(r.scheduledTime);
      if (day == today) return true;
      // Si quedó sin completar de un día anterior, se muestra como tardío en HOY.
      return !r.isCompleted && day.isBefore(today);
    }).toList();

    // Pendientes primero por hora, completados del día al final.
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.scheduledTime.compareTo(b.scheduledTime);
    });
    return list;
  }

  /// Recordatorios programados para MAÑANA.
  List<CareReminderItemModel> get tomorrowReminders {
    final tomorrow = _dayOnly(DateTime.now()).add(const Duration(days: 1));
    return reminders
        .where((r) => !r.isCompleted && _dayOnly(r.scheduledTime) == tomorrow)
        .toList(growable: false);
  }

  /// Recordatorios PRÓXIMOS (pasado mañana en adelante).
  List<CareReminderItemModel> get upcomingReminders {
    final tomorrow = _dayOnly(DateTime.now()).add(const Duration(days: 1));
    return reminders
        .where(
          (r) => !r.isCompleted && _dayOnly(r.scheduledTime).isAfter(tomorrow),
        )
        .toList(growable: false);
  }

  /// Alertas IA sin leer (activas).
  List<IaAlertModel> get unreadIaAlerts =>
      iaAlerts.where((a) => !a.isDeleted && !a.isRead).toList(growable: false);

  /// Alertas IA ya revisadas (activas).
  List<IaAlertModel> get readIaAlerts =>
      iaAlerts.where((a) => !a.isDeleted && a.isRead).toList(growable: false);

  /// Alertas IA eliminadas hace menos de 7 días.
  List<IaAlertModel> get deletedRecentIaAlerts {
    final now = DateTime.now();
    return iaAlerts
        .where((a) => a.isDeleted && a.isWithinSevenDaysOfDeletion(now))
        .toList(growable: false);
  }

  /// Cantidad de alertas IA sin leer (para el badge de cabecera).
  int get unreadIaAlertsCount => unreadIaAlerts.length;

  /// Cantidad de recordatorios pendientes del día actual (para el badge de cabecera).
  int get todayPendingCount =>
      todayReminders.where((r) => !r.isCompleted).length;

  AlertsLoaded copyWith({
    String? userName,
    String? avatarUrl,
    List<IaAlertModel>? iaAlerts,
    List<CareReminderItemModel>? reminders,
    List<PlantSelectOption>? plantOptions,
    List<GroupFilterOption>? groupOptions,
    AlertsTab? selectedTab,
    Set<String>? busyReminderIds,
    bool? isSavingForm,
    String? notice,
    bool noticeIsError = false,
    bool clearNotice = false,
  }) {
    return AlertsLoaded(
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      iaAlerts: iaAlerts ?? this.iaAlerts,
      reminders: reminders ?? this.reminders,
      plantOptions: plantOptions ?? this.plantOptions,
      groupOptions: groupOptions ?? this.groupOptions,
      selectedTab: selectedTab ?? this.selectedTab,
      busyReminderIds: busyReminderIds ?? this.busyReminderIds,
      isSavingForm: isSavingForm ?? this.isSavingForm,
      notice: clearNotice ? null : notice,
      noticeIsError: clearNotice ? false : noticeIsError,
    );
  }
}

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({AlertsRepository? repository})
    : _repository =
          repository ??
          AlertsRepository(
            datasource: AlertsDatasource(
              supabaseClient: const AppSupabaseClient(),
            ),
          ),
      super(const AlertsInitial()) {
    on<LoadAlertsModule>(_onLoad);
    on<RefreshAlertsModule>(_onRefresh);
    on<AlertsTabChanged>(_onTabChanged);
    on<CreateReminderRequested>(_onCreateReminder);
    on<UpdateReminderRequested>(_onUpdateReminder);
    on<CompleteReminderRequested>(_onCompleteReminder);
    on<SnoozeReminderRequested>(_onSnoozeReminder);
    on<DeleteReminderRequested>(_onDeleteReminder);
    on<MarkIaAlertAsReadRequested>(_onMarkIaAlertAsRead);
    on<DeleteIaAlertRequested>(_onDeleteIaAlert);
    on<RestoreIaAlertRequested>(_onRestoreIaAlert);
  }

  final AlertsRepository _repository;

  Future<void> _onLoad(
    LoadAlertsModule event,
    Emitter<AlertsState> emit,
  ) async {
    emit(const AlertsLoading());
    await _fetchAll(emit, isRefresh: false);
  }

  Future<void> _onRefresh(
    RefreshAlertsModule event,
    Emitter<AlertsState> emit,
  ) async {
    final hasData = state is AlertsLoaded;
    if (!hasData) emit(const AlertsLoading());
    await _fetchAll(emit, isRefresh: hasData);
  }

  void _onTabChanged(AlertsTabChanged event, Emitter<AlertsState> emit) {
    final current = state;
    if (current is! AlertsLoaded) return;
    emit(current.copyWith(selectedTab: event.tab, clearNotice: true));
  }

  Future<void> _onCreateReminder(
    CreateReminderRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded || current.isSavingForm) return;

    emit(current.copyWith(isSavingForm: true, clearNotice: true));

    try {
      await _repository.createReminder(
        plantId: event.plantId,
        treatmentAction: event.treatmentAction,
        iconName: event.iconName,
        scheduledTime: event.scheduledTime,
        isRecurrent: event.isRecurrent,
        recurrenceDays: event.recurrenceDays,
      );

      final data = await _repository.loadAlertsModuleData();
      emit(
        current.copyWith(
          iaAlerts: data.iaAlerts,
          reminders: data.reminders,
          plantOptions: data.plantOptions,
          groupOptions: data.groupOptions,
          isSavingForm: false,
          notice: 'Recordatorio creado correctamente',
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isSavingForm: false,
          notice: 'No se pudo crear el recordatorio',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onUpdateReminder(
    UpdateReminderRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded || current.isSavingForm) return;

    emit(current.copyWith(isSavingForm: true, clearNotice: true));

    try {
      await _repository.updateReminder(
        reminderId: event.reminderId,
        treatmentAction: event.treatmentAction,
        iconName: event.iconName,
        scheduledTime: event.scheduledTime,
        isRecurrent: event.isRecurrent,
        recurrenceDays: event.recurrenceDays,
      );

      final data = await _repository.loadAlertsModuleData();
      emit(
        current.copyWith(
          iaAlerts: data.iaAlerts,
          reminders: data.reminders,
          isSavingForm: false,
          notice: 'Recordatorio actualizado',
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isSavingForm: false,
          notice: 'No se pudo actualizar el recordatorio',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onCompleteReminder(
    CompleteReminderRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;
    if (current.busyReminderIds.contains(event.reminderId)) return;

    emit(
      current.copyWith(
        busyReminderIds: {...current.busyReminderIds, event.reminderId},
        clearNotice: true,
      ),
    );

    try {
      await _repository.completeReminder(event.reminderId);
      final data = await _repository.loadAlertsModuleData();
      final remaining = {...current.busyReminderIds}..remove(event.reminderId);

      emit(
        current.copyWith(
          iaAlerts: data.iaAlerts,
          reminders: data.reminders,
          busyReminderIds: remaining,
          notice: 'Cuidado marcado como completado',
        ),
      );
    } catch (_) {
      final remaining = {...current.busyReminderIds}..remove(event.reminderId);
      emit(
        current.copyWith(
          busyReminderIds: remaining,
          notice: 'No se pudo completar el recordatorio',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onSnoozeReminder(
    SnoozeReminderRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;
    final id = event.reminder.id;
    if (current.busyReminderIds.contains(id)) return;

    emit(
      current.copyWith(
        busyReminderIds: {...current.busyReminderIds, id},
        clearNotice: true,
      ),
    );

    try {
      await _repository.snoozeReminderByOneHour(event.reminder);
      final data = await _repository.loadAlertsModuleData();
      final remaining = {...current.busyReminderIds}..remove(id);

      emit(
        current.copyWith(
          iaAlerts: data.iaAlerts,
          reminders: data.reminders,
          busyReminderIds: remaining,
          notice: 'Se añadió 1 hora adicional al recordatorio',
        ),
      );
    } catch (_) {
      final remaining = {...current.busyReminderIds}..remove(id);
      emit(
        current.copyWith(
          busyReminderIds: remaining,
          notice: 'No se pudo posponer el recordatorio',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminderRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;
    if (current.busyReminderIds.contains(event.reminderId)) return;

    emit(
      current.copyWith(
        busyReminderIds: {...current.busyReminderIds, event.reminderId},
        clearNotice: true,
      ),
    );

    try {
      await _repository.deleteReminder(event.reminderId);
      final data = await _repository.loadAlertsModuleData();
      final remaining = {...current.busyReminderIds}..remove(event.reminderId);

      emit(
        current.copyWith(
          iaAlerts: data.iaAlerts,
          reminders: data.reminders,
          busyReminderIds: remaining,
          notice: 'Recordatorio eliminado',
        ),
      );
    } catch (_) {
      final remaining = {...current.busyReminderIds}..remove(event.reminderId);
      emit(
        current.copyWith(
          busyReminderIds: remaining,
          notice: 'No se pudo eliminar el recordatorio',
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onMarkIaAlertAsRead(
    MarkIaAlertAsReadRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    final targetIndex = current.iaAlerts.indexWhere(
      (a) => a.id == event.alertId,
    );
    if (targetIndex == -1 || current.iaAlerts[targetIndex].isRead) return;

    // Actualización optimista inmediata al abrir el detalle
    final updatedList = [...current.iaAlerts];
    updatedList[targetIndex] = updatedList[targetIndex].copyWith(isRead: true);
    emit(current.copyWith(iaAlerts: updatedList, clearNotice: true));

    try {
      await _repository.markIaAlertAsRead(event.alertId);
    } catch (_) {
      // Si falla red, revertir silenciosamente
      final latest = state;
      if (latest is AlertsLoaded) {
        final reverted = [...latest.iaAlerts];
        final idx = reverted.indexWhere((a) => a.id == event.alertId);
        if (idx != -1) {
          reverted[idx] = reverted[idx].copyWith(isRead: false);
          emit(latest.copyWith(iaAlerts: reverted));
        }
      }
    }
  }

  Future<void> _onDeleteIaAlert(
    DeleteIaAlertRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    final now = DateTime.now();
    final updatedList = current.iaAlerts
        .map((a) => a.id == event.alertId ? a.copyWith(deletedAt: now) : a)
        .toList(growable: false);

    emit(
      current.copyWith(
        iaAlerts: updatedList,
        notice: 'Alerta movida a eliminadas (visible por 7 días)',
      ),
    );

    try {
      await _repository.deleteIaAlert(event.alertId);
    } catch (_) {
      final data = await _repository.loadAlertsModuleData();
      final latest = state;
      if (latest is AlertsLoaded) {
        emit(
          latest.copyWith(
            iaAlerts: data.iaAlerts,
            notice: 'No se pudo eliminar la alerta',
            noticeIsError: true,
          ),
        );
      }
    }
  }

  Future<void> _onRestoreIaAlert(
    RestoreIaAlertRequested event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    final updatedList = current.iaAlerts
        .map(
          (a) => a.id == event.alertId ? a.copyWith(clearDeletedAt: true) : a,
        )
        .toList(growable: false);

    emit(
      current.copyWith(
        iaAlerts: updatedList,
        notice: 'Alerta restaurada correctamente',
      ),
    );

    try {
      await _repository.restoreIaAlert(event.alertId);
    } catch (_) {
      final data = await _repository.loadAlertsModuleData();
      final latest = state;
      if (latest is AlertsLoaded) {
        emit(
          latest.copyWith(
            iaAlerts: data.iaAlerts,
            notice: 'No se pudo restaurar la alerta',
            noticeIsError: true,
          ),
        );
      }
    }
  }

  Future<void> _fetchAll(
    Emitter<AlertsState> emit, {
    required bool isRefresh,
  }) async {
    try {
      final data = await _repository.loadAlertsModuleData();
      final current = state;

      if (current is AlertsLoaded) {
        emit(
          current.copyWith(
            userName: data.userName,
            avatarUrl: data.avatarUrl,
            iaAlerts: data.iaAlerts,
            reminders: data.reminders,
            plantOptions: data.plantOptions,
            groupOptions: data.groupOptions,
            clearNotice: true,
          ),
        );
      } else {
        emit(
          AlertsLoaded(
            userName: data.userName,
            avatarUrl: data.avatarUrl,
            iaAlerts: data.iaAlerts,
            reminders: data.reminders,
            plantOptions: data.plantOptions,
            groupOptions: data.groupOptions,
          ),
        );
      }
    } on PostgrestException {
      _handleFailure(
        emit,
        isRefresh: isRefresh,
        message: 'Error al consultar tus alertas en el servidor.',
      );
    } catch (_) {
      _handleFailure(
        emit,
        isRefresh: isRefresh,
        message: 'No se pudo cargar el Centro de Alertas. Revisa tu conexión.',
      );
    }
  }

  void _handleFailure(
    Emitter<AlertsState> emit, {
    required bool isRefresh,
    required String message,
  }) {
    final current = state;
    if (isRefresh && current is AlertsLoaded) {
      emit(current.copyWith(notice: message, noticeIsError: true));
    } else {
      emit(AlertsError(message));
    }
  }
}
