import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/features/alerts/data/datasources/alerts_datasource.dart';
import 'package:leafcare_ia/features/alerts/data/models/alert_model.dart';

/// Eventos de la pantalla de alertas.
sealed class AlertsEvent {
  const AlertsEvent();
}

class LoadAlerts extends AlertsEvent {
  const LoadAlerts();
}

class RefreshAlerts extends AlertsEvent {
  const RefreshAlerts();
}

class MarkAlertRead extends AlertsEvent {
  const MarkAlertRead(this.alertId);

  final String alertId;
}

class MarkAllAlertsRead extends AlertsEvent {
  const MarkAllAlertsRead();
}

class DeleteAlert extends AlertsEvent {
  const DeleteAlert(this.alertId);

  final String alertId;
}

/// Estados de la pantalla de alertas.
sealed class AlertsState {
  const AlertsState();
}

class AlertsInitial extends AlertsState {
  const AlertsInitial();
}

class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

class AlertsLoaded extends AlertsState {
  const AlertsLoaded(this.alerts);

  final List<AlertModel> alerts;

  /// Cuántas alertas todavía no se han leído.
  int get unreadCount => alerts.where((alert) => !alert.isRead).length;
}

class AlertsError extends AlertsState {
  const AlertsError(this.message);

  final String message;
}

/// Controla el estado de la pantalla de alertas.
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({AlertsDatasource? datasource})
    : _datasource = datasource ?? AlertsDatasource(),
      super(const AlertsInitial()) {
    on<LoadAlerts>(_onLoad);
    on<RefreshAlerts>(_onLoad);
    on<MarkAlertRead>(_onMarkRead);
    on<MarkAllAlertsRead>(_onMarkAllRead);
    on<DeleteAlert>(_onDelete);
  }

  final AlertsDatasource _datasource;

  Future<void> _onLoad(AlertsEvent event, Emitter<AlertsState> emit) async {
    emit(const AlertsLoading());

    try {
      final alerts = await _datasource.fetchAlerts();
      emit(AlertsLoaded(alerts));
    } catch (_) {
      emit(
        const AlertsError(
          'No se pudieron cargar las alertas. Revisa tu conexión.',
        ),
      );
    }
  }

  Future<void> _onMarkRead(
    MarkAlertRead event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    try {
      await _datasource.markAsRead(event.alertId);
    } catch (_) {
      // Si falla la actualización, se recarga y se muestra el estado real.
    }

    add(const RefreshAlerts());
  }

  Future<void> _onMarkAllRead(
    MarkAllAlertsRead event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    final unreadIds = current.alerts
        .where((alert) => !alert.isRead)
        .map((alert) => alert.id)
        .toList();

    if (unreadIds.isEmpty) return;

    try {
      await _datasource.markAllAsRead(unreadIds);
    } catch (_) {
      // Ignoramos el error y recargamos de todos modos.
    }

    add(const RefreshAlerts());
  }

  Future<void> _onDelete(DeleteAlert event, Emitter<AlertsState> emit) async {
    try {
      await _datasource.deleteAlert(event.alertId);
    } catch (_) {
      // Ignoramos el error y recargamos de todos modos.
    }

    add(const RefreshAlerts());
  }
}
