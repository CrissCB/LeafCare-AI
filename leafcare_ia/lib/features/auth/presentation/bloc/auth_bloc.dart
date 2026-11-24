import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:leafcare_ia/features/auth/data/models/auth_user_model.dart';
import 'package:leafcare_ia/features/auth/data/repositories/auth_repository.dart';

// --- EVENTOS ---
abstract class AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

class _AuthSessionChangedEvent extends AuthEvent {
  final sb.AuthChangeEvent event;
  final sb.Session? session;
  _AuthSessionChangedEvent(this.event, this.session);
}

class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;

  LoginSubmittedEvent({required this.email, required this.password});
}

/// Usuario ingresó el código de 6 dígitos en el paso 2FA.
class AuthTwoFactorSubmitted extends AuthEvent {
  AuthTwoFactorSubmitted({required this.challenge, required this.code});

  final TwoFactorChallenge challenge;
  final String code;
}

/// Reenviar código por correo durante el reto 2FA.
class AuthTwoFactorResendRequested extends AuthEvent {
  AuthTwoFactorResendRequested({required this.challenge});

  final TwoFactorChallenge challenge;
}

/// El usuario canceló la verificación 2FA: cerramos la sesión parcial.
class AuthTwoFactorCancelled extends AuthEvent {
  AuthTwoFactorCancelled();
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

class ResendVerificationEmailEvent extends AuthEvent {
  final String email;

  ResendVerificationEmailEvent({required this.email});
}

class ForgotPasswordRequestedEvent extends AuthEvent {
  final String email;
  ForgotPasswordRequestedEvent({required this.email});
}

class UpdatePasswordSubmittedEvent extends AuthEvent {
  final String newPassword;
  final String confirmPassword;
  UpdatePasswordSubmittedEvent({
    required this.newPassword,
    required this.confirmPassword,
  });
}

class LogoutRequestedEvent extends AuthEvent {}

// --- ESTADOS ---
abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {}

class UnauthenticatedState extends AuthState {}

class PasswordRecoveryState extends AuthState {}

/// Contraseña correcta, pero falta completar la verificación en dos pasos.
class AuthTwoFactorRequired extends AuthState {
  AuthTwoFactorRequired({
    required this.challenge,
    this.isVerifying = false,
    this.errorMessage,
    this.infoMessage,
  });

  final TwoFactorChallenge challenge;
  final bool isVerifying;
  final String? errorMessage;
  final String? infoMessage;

  AuthTwoFactorRequired copyWith({
    bool? isVerifying,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return AuthTwoFactorRequired(
      challenge: challenge,
      isVerifying: isVerifying ?? this.isVerifying,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

/// El usuario se registró, pero debe abrir el enlace enviado a su correo.
class EmailVerificationPendingState extends AuthState {
  final String email;
  final String message;

  EmailVerificationPendingState({
    required this.email,
    this.message = 'Te enviamos un enlace de confirmación a tu correo. Ábrelo para activar tu cuenta.',
  });
}

class PasswordResetSentState extends AuthState {
  final String email;
  final String message;
  PasswordResetSentState({required this.email, required this.message});
}

class PasswordUpdatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;
  final bool isEmailNotConfirmed;
  final String? email;

  AuthErrorState(this.message, {this.isEmailNotConfirmed = false, this.email});
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  late final StreamSubscription<sb.AuthState> _authSubscription;
  final AuthRepository repository;

  /// Evita que el stream `onAuthStateChange` emita `AuthenticatedState` antes
  /// de comprobar si el usuario tiene 2FA activo en `user_security`.
  bool _evaluatingTwoFactor = false;

  AuthBloc({required this.repository}) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<AuthTwoFactorSubmitted>(_onTwoFactorSubmitted);
    on<AuthTwoFactorResendRequested>(_onTwoFactorResendRequested);
    on<AuthTwoFactorCancelled>(_onTwoFactorCancelled);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
    on<ResendVerificationEmailEvent>(_onResendVerification);
    on<ForgotPasswordRequestedEvent>(_onForgotPassword);
    on<UpdatePasswordSubmittedEvent>(_onUpdatePassword);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<_AuthSessionChangedEvent>(_onAuthSessionChanged);

    _authSubscription = sb.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          add(_AuthSessionChangedEvent(data.event, data.session));
        });
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state is PasswordRecoveryState || state is AuthTwoFactorRequired) {
      return;
    }

    emit(AuthLoadingState());
    final hasSession = await repository.checkSession();

    if (state is PasswordRecoveryState || state is AuthTwoFactorRequired) {
      return;
    }

    if (hasSession) {
      emit(AuthenticatedState());
    } else {
      emit(UnauthenticatedState());
    }
  }

  void _onAuthSessionChanged(
    _AuthSessionChangedEvent event,
    Emitter<AuthState> emit,
  ) {
    if (event.event == sb.AuthChangeEvent.passwordRecovery) {
      emit(PasswordRecoveryState());
    } else if (event.event == sb.AuthChangeEvent.signedIn &&
        event.session != null &&
        !_evaluatingTwoFactor &&
        state is! PasswordRecoveryState &&
        state is! AuthTwoFactorRequired) {
      emit(AuthenticatedState());
    } else if (event.event == sb.AuthChangeEvent.signedOut) {
      _evaluatingTwoFactor = false;
      emit(UnauthenticatedState());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    _evaluatingTwoFactor = true;
    emit(AuthLoadingState());

    try {
      final result = await repository.login(
        email: event.email,
        password: event.password,
      );

      if (result.requiresEmailVerification) {
        _evaluatingTwoFactor = false;
        emit(EmailVerificationPendingState(email: result.email));
        return;
      }

      final challenge = await repository.checkTwoFactorRequirement(
        userId: result.userId,
        email: result.email,
      );

      _evaluatingTwoFactor = false;

      if (challenge != null) {
        emit(AuthTwoFactorRequired(challenge: challenge));
        return;
      }

      emit(AuthenticatedState());
    } on AuthFailureException catch (e) {
      _evaluatingTwoFactor = false;
      emit(
        AuthErrorState(
          e.message,
          isEmailNotConfirmed: e.isEmailNotConfirmed,
          email: event.email.trim(),
        ),
      );
    } catch (_) {
      _evaluatingTwoFactor = false;
      emit(AuthErrorState('No se pudo conectar con el servidor.'));
    }
  }

  Future<void> _onTwoFactorSubmitted(
    AuthTwoFactorSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthTwoFactorRequired) return;

    emit(
      currentState.copyWith(
        isVerifying: true,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await repository.verifyTwoFactorCode(
        challenge: event.challenge,
        code: event.code,
      );
      emit(AuthenticatedState());
    } on AuthFailureException catch (e) {
      emit(currentState.copyWith(isVerifying: false, errorMessage: e.message));
    } catch (_) {
      emit(
        currentState.copyWith(
          isVerifying: false,
          errorMessage:
              'Código inválido o expirado. Verifica e intenta de nuevo.',
        ),
      );
    }
  }

  Future<void> _onTwoFactorResendRequested(
    AuthTwoFactorResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthTwoFactorRequired) return;

    try {
      await repository.resendTwoFactorEmailCode(event.challenge.email);
      emit(
        currentState.copyWith(
          clearError: true,
          infoMessage: 'Enviamos un nuevo código a ${event.challenge.email}',
        ),
      );
    } on AuthFailureException catch (e) {
      emit(currentState.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(
        currentState.copyWith(
          errorMessage:
              'No se pudo reenviar el código. Intenta en unos segundos.',
        ),
      );
    }
  }

  Future<void> _onTwoFactorCancelled(
    AuthTwoFactorCancelled event,
    Emitter<AuthState> emit,
  ) async {
    _evaluatingTwoFactor = false;
    await repository.logout();
    emit(UnauthenticatedState());
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final result = await repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        passwordConfirm: event.passwordConfirm,
      );

      if (result.requiresEmailVerification) {
        emit(EmailVerificationPendingState(email: result.email));
      } else {
        emit(AuthenticatedState());
      }
    } on AuthFailureException catch (e) {
      emit(AuthErrorState(e.message));
    } catch (_) {
      emit(AuthErrorState('Error al crear la cuenta. Inténtalo de nuevo.'));
    }
  }

  Future<void> _onResendVerification(
    ResendVerificationEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await repository.resendVerificationEmail(event.email);
      emit(
        EmailVerificationPendingState(
          email: event.email,
          message:
              'Hemos reenviado el enlace de verificación a ${event.email}.',
        ),
      );
    } on AuthFailureException catch (e) {
      emit(
        AuthErrorState(
          e.message,
          isEmailNotConfirmed: true,
          email: event.email,
        ),
      );
    } catch (_) {
      emit(AuthErrorState('No se pudo reenviar el correo de verificación.'));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await repository.resetPassword(event.email);
      emit(
        PasswordResetSentState(
          email: event.email.trim(),
          message:
              'Enviamos un enlace de recuperación a ${event.email.trim()}.',
        ),
      );
    } on AuthFailureException catch (e) {
      emit(AuthErrorState(e.message));
    } catch (_) {
      emit(AuthErrorState('No se pudo enviar el correo de recuperación.'));
    }
  }

  Future<void> _onUpdatePassword(
    UpdatePasswordSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (event.newPassword != event.confirmPassword) {
      emit(AuthErrorState('Las contraseñas no coinciden.'));
      return;
    }
    if (event.newPassword.length < 6) {
      emit(AuthErrorState('La contraseña debe tener al menos 6 caracteres.'));
      return;
    }

    emit(AuthLoadingState());
    try {
      await repository.updatePassword(event.newPassword);
      emit(PasswordUpdatedState());
    } on AuthFailureException catch (e) {
      emit(AuthErrorState(e.message));
    } catch (_) {
      emit(AuthErrorState('No se pudo actualizar la contraseña.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    _evaluatingTwoFactor = false;
    await repository.logout();
    emit(UnauthenticatedState());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
