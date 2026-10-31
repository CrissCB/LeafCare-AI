import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/features/auth/data/datasources/auth_remote_datasource.dart';

// --- EVENTOS ---
abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
}

// --- ESTADOS ---
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDatasource datasource;

  AuthBloc({required this.datasource}) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // MODO PRUEBA: Esperamos medio segundo por efecto visual y damos éxito
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthSuccess());

      /* 
      // LÓGICA REAL (Descomentar cuando PocketBase esté listo)
      // await datasource.login(event.email, event.password);
      // emit(AuthSuccess());
      */
    } on ClientException catch (e) {
      final raw = (e.response['message'] as String?)?.trim();
      if (raw == null || raw.isEmpty || raw == 'Failed to authenticate.') {
        emit(AuthError('Correo o contraseña incorrectos'));
      } else {
        emit(AuthError(raw));
      }
    } catch (_) {
      emit(AuthError('Error de conexión con el servidor.'));
    }
  }
}
