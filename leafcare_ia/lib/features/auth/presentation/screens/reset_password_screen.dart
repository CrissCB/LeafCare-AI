import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/custom_button.dart';
import 'package:leafcare_ia/core/widgets/custom_textfield.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_layout.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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

  void _onSavePressed() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      UpdatePasswordSubmittedEvent(
        newPassword: _passwordController.text,
        confirmPassword: _confirmController.text,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.5, -1),
                  end: Alignment(0.5, 1),
                  colors: [
                    AppColors.heroStart,
                    AppColors.heroMid,
                    AppColors.heroEnd,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.neon12,
                      border: Border.all(color: AppColors.neon35, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: LeafLogo(size: 36)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nueva Contraseña',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crea una contraseña segura para tu cuenta',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is PasswordUpdatedState) {
                      _snack('Contraseña actualizada correctamente');
                      context.go('/dashboard');
                    } else if (state is AuthErrorState) {
                      _snack(state.message, error: true);
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is AuthLoadingState;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: 'Nueva Contraseña',
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          icon: Icons.lock_outline_rounded,
                          hint: 'Mínimo 8 caracteres',
                          obscure: _obscure1,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _confirmFocus.requestFocus(),
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscure1 = !_obscure1),
                            child: Icon(
                              _obscure1
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.slateLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Confirmar Contraseña',
                          controller: _confirmController,
                          focusNode: _confirmFocus,
                          icon: Icons.lock_reset_rounded,
                          hint: 'Repite tu contraseña',
                          obscure: _obscure2,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onSavePressed(),
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscure2 = !_obscure2),
                            child: Icon(
                              _obscure2
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.slateLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          label: 'Guardar contraseña',
                          loading: isLoading,
                          onTap: isLoading ? null : _onSavePressed,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
