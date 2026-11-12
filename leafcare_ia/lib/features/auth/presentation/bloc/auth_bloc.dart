import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    } on AuthException catch (e) {
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
    } on AuthException catch (e) {
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

  /// Traduce las excepciones típicas de Supabase GoTrue a mensajes legibles
  String _friendlyError(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return 'El correo electrónico ya está registrado.';
    }
    if (message.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (message.contains('rate limit exceeded')) {
      return 'Demasiados intentos. Inténtalo de nuevo en unos minutos.';
    }

    return e.message;
  }
}
