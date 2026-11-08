import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:leafcare_ia/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';

/// Eventos que puede recibir la pantalla principal.
sealed class DashboardEvent {
  const DashboardEvent();
}

/// Carga inicial de los datos.
class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

/// El usuario deslizó hacia abajo para actualizar.
class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}

/// El usuario marcó un recordatorio como completado.
class CompleteReminder extends DashboardEvent {
  const CompleteReminder(this.reminderId);

  final String reminderId;
}

/// Estados posibles de la pantalla principal.
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
    required this.userName,
    required this.plants,
    required this.unreadAlerts,
    required this.reminders,
  });

  final String userName;
  final List<UserPlantModel> plants;
  final int unreadAlerts;
  final List<CareReminderModel> reminders;
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}

/// Controla el estado de la pantalla principal.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({DashboardDatasource? datasource})
    : _datasource = datasource ?? DashboardDatasource(),
      super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onLoad);
    on<CompleteReminder>(_onCompleteReminder);
  }

  final DashboardDatasource _datasource;

  /// Carga todo lo que necesita la pantalla principal.
  Future<void> _onLoad(
    DashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    try {
      final userName = await _datasource.fetchUserName();
      final plants = await _datasource.fetchPlants();
      final unreadAlerts = await _datasource.fetchUnreadAlertsCount();
      final reminders = await _datasource.fetchTodayReminders();

      emit(
        DashboardLoaded(
          userName: userName,
          plants: plants,
          unreadAlerts: unreadAlerts,
          reminders: reminders,
        ),
      );
    } catch (_) {
      emit(
        const DashboardError(
          'No se pudieron cargar tus datos. Revisa tu conexión e inténtalo de nuevo.',
        ),
      );
    }
  }

  /// Marca un recordatorio como hecho y recarga la lista.
  Future<void> _onCompleteReminder(
    CompleteReminder event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _datasource.completeReminder(event.reminderId);
    } catch (_) {
      // Si falla, igual recargamos para mostrar el estado real.
    }

    add(const RefreshDashboard());
  }
}
