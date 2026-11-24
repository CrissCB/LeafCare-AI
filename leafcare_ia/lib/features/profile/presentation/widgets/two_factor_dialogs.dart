import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/profile/data/datasources/security_datasource.dart';

/// 1. Diálogo para elegir el método de doble autenticación ('APP' o 'EMAIL').
class ChooseTwoFactorMethodDialog extends StatelessWidget {
  const ChooseTwoFactorMethodDialog({super.key, this.currentType});

  final String? currentType;

  static Future<String?> show(BuildContext context, {String? currentType}) {
    return showDialog<String>(
      context: context,
      builder: (_) => ChooseTwoFactorMethodDialog(currentType: currentType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'Verificación en dos pasos',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.anthracite,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige cómo deseas recibir tu código de seguridad al iniciar sesión:',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 14),
          _MethodOptionCard(
            icon: Icons.phonelink_lock_rounded,
            title: 'Aplicación autenticadora',
            subtitle: 'Google Authenticator, Authy o Microsoft Authenticator',
            isCurrent: currentType == 'APP',
            onTap: () => Navigator.of(context).pop('APP'),
          ),
          const SizedBox(height: 10),
          _MethodOptionCard(
            icon: Icons.mark_email_read_outlined,
            title: 'Código al correo electrónico',
            subtitle: 'Recibe un código temporal de 6 dígitos en tu correo',
            isCurrent: currentType == 'EMAIL',
            onTap: () => Navigator.of(context).pop('EMAIL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _MethodOptionCard extends StatelessWidget {
  const _MethodOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCurrent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? AppColors.mint : AppColors.pageBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.anthracite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isCurrent
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isCurrent ? AppColors.primary : AppColors.slateLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. Modal para vincular una App Autenticadora (QR + clave secreta + código de 6 dígitos).
class VerifyTotpEnrollmentDialog extends StatefulWidget {
  const VerifyTotpEnrollmentDialog({
    super.key,
    required this.enrollment,
    required this.onVerifyCode,
  });

  final TotpEnrollmentData enrollment;
  final Future<void> Function(String code) onVerifyCode;

  static Future<bool> show(
    BuildContext context, {
    required TotpEnrollmentData enrollment,
    required Future<void> Function(String code) onVerifyCode,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VerifyTotpEnrollmentDialog(
        enrollment: enrollment,
        onVerifyCode: onVerifyCode,
      ),
    );
    return result == true;
  }

  @override
  State<VerifyTotpEnrollmentDialog> createState() =>
      _VerifyTotpEnrollmentDialogState();
}

class _VerifyTotpEnrollmentDialogState
    extends State<VerifyTotpEnrollmentDialog> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  String? _errorText;
  bool _copied = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _copySecret() async {
    await Clipboard.setData(ClipboardData(text: widget.enrollment.secret));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorText = 'Ingresa los 6 dígitos generados por la app');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.onVerifyCode(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorText = 'Código inválido o expirado. Inténtalo de nuevo.';
        });
      }
    }
  }

  /// Extrae el SVG limpio sin importar si Supabase lo devuelve crudo (`<svg...`)
  /// o codificado como Data URI (`data:image/svg+xml;utf8,<svg...`).
  String? _extractCleanSvg(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('<svg')) {
      return trimmed;
    }

    const prefix = 'data:image/svg+xml';
    if (trimmed.startsWith(prefix)) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1 && commaIndex + 1 < trimmed.length) {
        final payload = trimmed.substring(commaIndex + 1);
        return Uri.decodeComponent(payload);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cleanSvg = _extractCleanSvg(widget.enrollment.qrCodeSvg);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'Configurar App Autenticadora',
        style: GoogleFonts.outfit(
          fontSize: 17.5,
          fontWeight: FontWeight.w700,
          color: AppColors.anthracite,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Escanea el código QR con Google Authenticator o Authy, o copia la clave manual:',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 12),

            // Bloque superior: Código QR
            if (cleanSvg != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: SvgPicture.string(cleanSvg, width: 176, height: 176),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Bloque inferior: Clave secreta manual con botón de copiar
            Center(
              child: Text(
                '¿No puedes escanear el QR? Usa esta clave:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.slateLight,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.enrollment.secret,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _copySecret,
                    tooltip: _copied ? 'Copiado' : 'Copiar clave',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              '2. Ingresa el código de 6 dígitos que genera la app:',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                errorText: _errorText,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Text('Verificar y activar'),
        ),
      ],
    );
  }
}

/// 3. Modal para verificar el código OTP enviado al correo electrónico.
class VerifyEmailOtpDialog extends StatefulWidget {
  const VerifyEmailOtpDialog({
    super.key,
    required this.email,
    required this.onVerifyCode,
    required this.onResendCode,
  });

  final String email;
  final Future<void> Function(String code) onVerifyCode;
  final Future<void> Function() onResendCode;

  static Future<bool> show(
    BuildContext context, {
    required String email,
    required Future<void> Function(String code) onVerifyCode,
    required Future<void> Function() onResendCode,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VerifyEmailOtpDialog(
        email: email,
        onVerifyCode: onVerifyCode,
        onResendCode: onResendCode,
      ),
    );
    return result == true;
  }

  @override
  State<VerifyEmailOtpDialog> createState() => _VerifyEmailOtpDialogState();
}

class _VerifyEmailOtpDialogState extends State<VerifyEmailOtpDialog> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  bool _resending = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorText = 'Ingresa el código de 6 dígitos');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.onVerifyCode(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorText = 'Código incorrecto o expirado.';
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await widget.onResendCode();
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'Verifica tu correo',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.anthracite,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enviamos un código de 6 dígitos a ${widget.email}. Ingrésalo para activar el 2FA:',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resending ? null : _resend,
              child: Text(
                _resending ? 'Reenviando...' : 'Reenviar código',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
