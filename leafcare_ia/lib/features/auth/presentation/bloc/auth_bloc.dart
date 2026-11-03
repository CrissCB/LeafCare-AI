import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/features/auth/data/datasources/auth_remote_datasource.dart';

// --- EVENTOS ---
abstract class AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;
  LoginSubmittedEvent({required this.email, required this.password});
}

class RegisterSubmittedEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String passwordConfirm;

  RegisterSubmittedEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });
}

class LogoutRequestedEvent extends AuthEvent {}

// --- ESTADOS ---
abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {}

class UnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;
  AuthErrorState(this.message);
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDatasource datasource;

  AuthBloc({required this.datasource}) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    final hasSession = await datasource.checkSession();
    if (hasSession) {
      emit(AuthenticatedState());
    } else {
      emit(UnauthenticatedState());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await datasource.login(event.email, event.password);
      emit(AuthenticatedState());
    } on ClientException catch (e) {
      emit(AuthErrorState(_friendlyError(e)));
    } catch (_) {
      emit(AuthErrorState('No se pudo conectar con el servidor.'));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await datasource.register(
        name: event.name,
        email: event.email,
        password: event.password,
        passwordConfirm: event.passwordConfirm,
      );
      emit(AuthenticatedState());
    } on ClientException catch (e) {
      emit(AuthErrorState(_friendlyError(e)));
    } catch (_) {
      emit(AuthErrorState('Error al crear la cuenta. Inténtalo de nuevo.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    await datasource.logout();
    emit(UnauthenticatedState());
  }

  String _friendlyError(ClientException e) {
    final raw = (e.response['message'] as String?)?.trim();
    if (raw == null || raw.isEmpty || raw == 'Failed to authenticate.') {
      return 'Credenciales incorrectas o correo ya registrado.';
    }
    return raw;
  }
}
