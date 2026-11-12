import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:leafcare_ia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:leafcare_ia/features/auth/data/repositories/auth_repository.dart';

/// Objeto limpio que recibe tu BLoC/UI sin depender de `supabase_flutter`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remoteDatasource});

  final AuthRemoteDatasource remoteDatasource;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDatasource.login(email, password);
      final user = response.user;

      if (user == null) {
        throw const AuthFailureException(
          'No se pudo obtener la sesión del usuario.',
        );
      }

      return AuthResult(
        userId: user.id,
        email: user.email ?? email.trim(),
        requiresEmailVerification: response.session == null,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on SocketException {
      throw const AuthFailureException(
        'Sin conexión a internet. Verifica tu red.',
      );
    } catch (_) {
      throw const AuthFailureException(
        'Ocurrió un error inesperado al iniciar sesión.',
      );
    }
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await remoteDatasource.register(
        name: name,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthFailureException('No se pudo completar el registro.');
      }

      return AuthResult(
        userId: user.id,
        email: user.email ?? email.trim(),
        // En Supabase, si "Confirm email" está activo, session llega en null
        requiresEmailVerification: response.session == null,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on SocketException {
      throw const AuthFailureException(
        'Sin conexión a internet. Verifica tu red.',
      );
    } catch (_) {
      throw const AuthFailureException(
        'No se pudo crear la cuenta. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    try {
      await remoteDatasource.resendVerificationEmail(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on SocketException {
      throw const AuthFailureException('Sin conexión a internet.');
    } catch (_) {
      throw const AuthFailureException(
        'No se pudo reenviar el correo de verificación.',
      );
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await remoteDatasource.resetPassword(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on SocketException {
      throw const AuthFailureException('Sin conexión a internet.');
    } catch (_) {
      throw const AuthFailureException(
        'No se pudo enviar el correo de recuperación.',
      );
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await remoteDatasource.updatePassword(newPassword);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on SocketException {
      throw const AuthFailureException('Sin conexión a internet.');
    } catch (_) {
      throw const AuthFailureException('No se pudo actualizar la contraseña.');
    }
  }

  @override
  Future<bool> checkSession() async {
    try {
      return await remoteDatasource.checkSession();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await remoteDatasource.logout();
  }

  AuthFailureException _mapAuthException(AuthException error) {
    final code = error.code?.toLowerCase() ?? '';
    final msg = error.message.toLowerCase();

    if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return const AuthFailureException(
        'Tu correo aún no ha sido verificado. Revisa tu bandeja de entrada o spam.',
        isEmailNotConfirmed: true,
      );
    }

    if (code == 'invalid_credentials' ||
        msg.contains('invalid login credentials')) {
      return const AuthFailureException('Correo o contraseña incorrectos.');
    }

    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return const AuthFailureException('Este correo ya está registrado.');
    }

    if (code == 'weak_password' ||
        msg.contains('password should be at least')) {
      return const AuthFailureException(
        'La contraseña es muy débil. Usa al menos 6 caracteres.',
      );
    }

    if (code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
      return const AuthFailureException(
        'Has solicitado demasiados correos seguidos. Espera unos minutos.',
      );
    }

    return AuthFailureException(error.message);
  }
}
