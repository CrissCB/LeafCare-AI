import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/custom_button.dart';
import 'package:leafcare_ia/features/auth/data/models/auth_user_model.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';

/// Formulario de segundo factor que reemplaza temporalmente los campos de correo/clave
/// cuando `AuthBloc` emite [AuthTwoFactorRequired].
class LoginTwoFactorCard extends StatefulWidget {
  const LoginTwoFactorCard({
    super.key,
    required this.state,
    required this.onVerify,
    required this.onResendEmail,
    required this.onCancel,
  });

  final AuthTwoFactorRequired state;
  final ValueChanged<String> onVerify;
  final VoidCallback onResendEmail;
  final VoidCallback onCancel;

  @override
  State<LoginTwoFactorCard> createState() => _LoginTwoFactorCardState();
}

class _LoginTwoFactorCardState extends State<LoginTwoFactorCard> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _localError = 'Ingresa los 6 dígitos de verificación.');
      return;
    }
    setState(() => _localError = null);
    widget.onVerify(code);
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.state.challenge;
    final isEmail = challenge.method == TwoFactorMethod.email;
    final displayError = _localError ?? widget.state.errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmail
                    ? Icons.mark_email_read_outlined
                    : Icons.phonelink_lock_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verificación en dos pasos',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.anthracite,
                    ),
                  ),
                  Text(
                    isEmail
                        ? 'Código enviado a ${challenge.email}'
                        : 'Código de tu aplicación autenticadora',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.slateLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            isEmail
                ? 'Revisa tu bandeja de entrada (o spam) e ingresa el código temporal de 6 dígitos que enviamos a tu correo.'
                : 'Abre Google Authenticator, Authy o tu app vinculada e ingresa el código de 6 dígitos actual.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Código de seguridad',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.anthracite,
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _codeController,
          focusNode: _codeFocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _submit(),
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
            color: AppColors.anthracite,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
              color: AppColors.slateLight.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
          ),
        ),

        if (displayError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayError,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],

        if (widget.state.infoMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.state.infoMessage!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],

        const SizedBox(height: 22),

        CustomButton(
          label: 'Verificar e ingresar',
          loading: widget.state.isVerifying,
          onTap: widget.state.isVerifying ? null : _submit,
        ),

        if (isEmail) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: widget.state.isVerifying ? null : widget.onResendEmail,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(
                'Reenviar código al correo',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],

        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: widget.state.isVerifying ? null : widget.onCancel,
            child: Text(
              'Cancelar y volver al inicio de sesión',
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate),
            ),
          ),
        ),
      ],
    );
  }
}
