import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/custom_button.dart';
import 'package:leafcare_ia/core/widgets/custom_textfield.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_layout.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_footer.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/register_header.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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

  void _onRegisterPressed() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _snack('Por favor completa todos los campos', error: true);
      return;
    }

    if (password != confirm) {
      _snack('Las contraseñas no coinciden', error: true);
      return;
    }

    if (password.length < 8) {
      _snack('La contraseña debe tener al menos 8 caracteres', error: true);
      return;
    }

    context.read<AuthBloc>().add(
      RegisterSubmittedEvent(
        name: name,
        email: email,
        password: password,
        passwordConfirm: confirm,
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
            const RegisterHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // NOMBRE COMPLETO
                    CustomTextField(
                      label: 'Nombre Completo',
                      controller: _nameController,
                      focusNode: _nameFocus,
                      icon: Icons.person_outline_rounded,
                      hint: 'Ana García López',
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _emailFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),

                    // CORREO ELECTRÓNICO
                    CustomTextField(
                      label: 'Correo Electrónico',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      icon: Icons.mail_outline_rounded,
                      hint: 'ana@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),

                    // CONTRASEÑA
                    CustomTextField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      icon: Icons.lock_outline_rounded,
                      hint: '••••••••',
                      obscure: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
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
                    const SizedBox(height: 14),

                    // CONFIRMAR CONTRASEÑA
                    CustomTextField(
                      label: 'Confirmar Contraseña',
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      icon: Icons.fact_check_outlined,
                      hint: '••••••••',
                      obscure: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          _acceptedTerms ? _onRegisterPressed() : null,
                      suffix: GestureDetector(
                        onTap: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        child: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.slateLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CHECKBOX DE TÉRMINOS Y CONDICIONES
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                            onChanged: (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.slate,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'Términos y Condiciones',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const TextSpan(text: ' y la '),
                                TextSpan(
                                  text: 'Política de Privacidad',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const TextSpan(text: ' de LeafCare AI.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // BOTÓN CREAR CUENTA
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthenticatedState)
                          context.go('/dashboard');
                      },
                      builder: (context, state) {
                        final isButtonActive =
                            _acceptedTerms && state is! AuthLoadingState;
                        return Opacity(
                          opacity: _acceptedTerms ? 1.0 : 0.4,
                          child: CustomButton(
                            label: 'Crear Cuenta',
                            loading: state is AuthLoadingState,
                            onTap: isButtonActive ? _onRegisterPressed : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // FOOTER
                    AuthFooter(
                      questionText: '¿Ya tienes cuenta? ',
                      actionText: 'Inicia sesión',
                      onTap: () => context.pop(),
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
