import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/custom_button.dart';
import 'package:leafcare_ia/core/widgets/custom_textfield.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/social_button.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_layout.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_footer.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _comingSoon(String label) => _snack('$label: próximamente');

  void _onLoginPressed() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      LoginSubmitted(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: AuthLayout(
        child: Column(
          children: [
            const _LoginHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.anthracite,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CAMPO DE CORREO
                    CustomTextField(
                      label: 'Correo Electrónico',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      icon: Icons.mail_outline_rounded,
                      hint: 'usuario@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),

                    // CAMPO DE CONTRASEÑA
                    CustomTextField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      icon: Icons.lock_outline_rounded,
                      hint: '••••••••',
                      obscure: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _onLoginPressed(),
                      suffix: GestureDetector(
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.slateLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ¿OLVIDASTE TU CONTRASEÑA?
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _comingSoon('Recuperar contraseña'),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BOTÓN INICIAR SESIÓN CON BLoC
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthSuccess) {
                          context.go('/dashboard');
                        } else if (state is AuthError) {
                          _snack(state.message, error: true);
                        }
                      },
                      builder: (context, state) {
                        return CustomButton(
                          label: 'Iniciar Sesión',
                          loading: state is AuthLoading,
                          onTap: state is AuthLoading ? null : _onLoginPressed,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // BOTÓN DE GOOGLE
                    SocialButton(
                      label: 'Continuar con Google',
                      onTap: () => _comingSoon('Continuar con Google'),
                    ),
                    const SizedBox(height: 28),

                    // FOOTER DE REGISTRO
                    AuthFooter(
                      questionText: '¿No tienes cuenta? ',
                      actionText: 'Regístrate aquí',
                      onTap: () => context.push(
                        '/register',
                      ), // Navega a la pantalla de registro
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// CABECERA ÚNICA DEL LOGIN
// =========================================================================

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _circle(180, AppColors.neon06),
          ),
          Positioned(
            bottom: -30,
            left: -40,
            child: _circle(120, AppColors.neon05),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 36),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.neon12,
                    border: Border.all(color: AppColors.neon35, width: 1.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(child: LeafLogo(size: 40)),
                ),
                const SizedBox(height: 12),
                Text(
                  'LeafCare AI',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Diagnóstico inteligente para tus plantas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
