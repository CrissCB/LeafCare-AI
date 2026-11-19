import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/custom_button.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:leafcare_ia/features/auth/presentation/widgets/auth_layout.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  void _snack(BuildContext context, String message, {bool error = false}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: AuthLayout(
        child: Column(
          children: [
            _AuthSimpleHeader(
              title: 'Verifica tu correo',
              subtitle: 'Un último paso para activar tu cuenta',
              onBack: () => context.go('/login'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is EmailVerificationPendingState) {
                      _snack(context, state.message);
                    } else if (state is AuthErrorState) {
                      _snack(context, state.message, error: true);
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is AuthLoadingState;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Revisa tu bandeja de entrada',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.anthracite,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enviamos un enlace de confirmación a:',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: AppColors.slateLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email.isNotEmpty ? email : 'tu correo electrónico',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.anthracite,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.slateLight.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Haz clic en el enlace del correo para activar tu cuenta. Si no lo ves en unos minutos, revisa la carpeta de Spam o Correo no deseado.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.slateLight,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        CustomButton(
                          label: 'Ya verifiqué mi correo',
                          onTap: () => context.go('/login'),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: (isLoading || email.isEmpty)
                              ? null
                              : () => context.read<AuthBloc>().add(
                                  ResendVerificationEmailEvent(email: email),
                                ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            isLoading
                                ? 'Reenviando...'
                                : 'Reenviar correo de verificación',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
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

class _AuthSimpleHeader extends StatelessWidget {
  const _AuthSimpleHeader({
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 24, 32),
          child: Column(
            children: [
              if (onBack != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
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
                  border: Border.all(color: AppColors.neon35, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(child: LeafLogo(size: 32)),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
