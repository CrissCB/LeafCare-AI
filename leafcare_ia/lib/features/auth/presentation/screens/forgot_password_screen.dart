import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/custom_button.dart';
import 'package:leafcare_ia/core/widgets/custom_textfield.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_footer.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final _emailFocus = FocusNode();
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
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

  void _onSendPressed() {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _snack('Ingresa un correo electrónico válido', error: true);
      return;
    }

    context.read<AuthBloc>().add(ForgotPasswordRequestedEvent(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: AuthLayout(
        child: Column(
          children: [
            // Cabecera
            Container(
              width: double.infinity,
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
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 24, 32),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.neon12,
                          border: Border.all(
                            color: AppColors.neon35,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(child: LeafLogo(size: 32)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recuperar Contraseña',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Te enviaremos un enlace para restablecerla',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is PasswordResetSentState) {
                      setState(() => _emailSent = true);
                      _snack(state.message);
                    } else if (state is AuthErrorState) {
                      _snack(state.message, error: true);
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is AuthLoadingState;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.anthracite,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Escribe el correo asociado a tu cuenta de LeafCare AI y recibirás instrucciones para crear una nueva clave.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.slateLight,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        CustomTextField(
                          label: 'Correo Electrónico',
                          controller: _emailController,
                          focusNode: _emailFocus,
                          icon: Icons.mail_outline_rounded,
                          hint: 'usuario@email.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onSendPressed(),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          label: _emailSent
                              ? 'Reenviar enlace'
                              : 'Enviar enlace de recuperación',
                          loading: isLoading,
                          onTap: isLoading ? null : _onSendPressed,
                        ),
                        if (_emailSent) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Revisa tu bandeja de entrada o spam y haz clic en el enlace para continuar.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.anthracite,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        AuthFooter(
                          questionText: '¿Recordaste tu contraseña? ',
                          actionText: 'Inicia sesión',
                          onTap: () => context.go('/login'),
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
