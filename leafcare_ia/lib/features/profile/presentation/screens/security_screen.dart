import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';
import 'package:leafcare_ia/features/profile/data/datasources/security_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/security_model.dart';

/// Pantalla "Seguridad": verificación en dos pasos y estado de la cuenta.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final SecurityDatasource _datasource = SecurityDatasource();

  SecurityModel? _security;
  bool _loading = true;
  bool _saving = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final security = await _datasource.fetchSecurity();
      if (!mounted) return;
      setState(() {
        _security = security;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  /// Activa o desactiva la verificación en dos pasos.
  Future<void> _toggleTwoFactor(bool enabled) async {
    final current = _security;
    if (current == null) return;

    // Si la va a activar, preguntamos cómo quiere verificar.
    var type = current.twoFactorType;
    if (enabled) {
      final chosen = await showDialog<String>(
        context: context,
        builder: (_) => const _TwoFactorTypeDialog(),
      );
      if (chosen == null) return;
      type = chosen;
    }

    setState(() => _saving = true);

    try {
      await _datasource.updateTwoFactor(
        recordId: current.recordId,
        enabled: enabled,
        type: type,
      );

      if (!mounted) return;
      setState(() {
        _security = SecurityModel(
          recordId: current.recordId,
          is2faEnabled: enabled,
          twoFactorType: type,
          failedAttempts: current.failedAttempts,
          lockedUntil: current.lockedUntil,
        );
      });

      _snack(
        enabled
            ? 'Verificación en dos pasos activada'
            : 'Verificación en dos pasos desactivada',
      );
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo guardar el cambio', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const SubPageHeader(
            title: 'Seguridad',
            subtitle: 'Protege tu cuenta con una capa extra.',
            icon: Icons.shield_outlined,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingIndicator();

    if (_error || _security == null) {
      return EmptyStateView(
        icon: Icons.gpp_bad_outlined,
        title: 'No se pudo cargar tu seguridad',
        subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
        onRetry: _load,
      );
    }

    final security = _security!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        // Estado general de la cuenta
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: security.is2faEnabled ? AppColors.mint : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: security.is2faEnabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: security.is2faEnabled
                      ? AppColors.primary
                      : AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  security.is2faEnabled
                      ? Icons.verified_user_rounded
                      : Icons.security_rounded,
                  color: security.is2faEnabled
                      ? AppColors.white
                      : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      security.is2faEnabled
                          ? 'Tu cuenta está protegida'
                          : 'Tu cuenta puede estar más segura',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.anthracite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      security.is2faEnabled
                          ? 'Verificación activa con ${security.twoFactorLabel}.'
                          : 'Activa la verificación en dos pasos para protegerla.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Verificación en dos pasos',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.anthracite,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phonelink_lock_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      security.is2faEnabled ? 'Activada' : 'Desactivada',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.anthracite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      security.is2faEnabled
                          ? 'Método: ${security.twoFactorLabel}'
                          : 'Pide un código extra al iniciar sesión.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.slateLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: security.is2faEnabled,
                onChanged: _saving ? null : _toggleTwoFactor,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Contraseña',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.anthracite,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cambia tu contraseña cada cierto tiempo y no la compartas.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/account'),
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: const Text('Ir a cambiar contraseña'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.inputBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Actividad de la cuenta',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.anthracite,
          ),
        ),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.login_rounded,
          label: 'Intentos fallidos',
          value: '${security.failedAttempts}',
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: security.isLocked
              ? Icons.lock_clock_rounded
              : Icons.lock_open_rounded,
          label: 'Estado de la cuenta',
          value: security.isLocked ? 'Bloqueada temporalmente' : 'Activa',
        ),
      ],
    );
  }
}

/// Fila informativa con ícono, etiqueta y valor.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.slate,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.anthracite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ventana para elegir cómo se quiere verificar el usuario.
class _TwoFactorTypeDialog extends StatelessWidget {
  const _TwoFactorTypeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        '¿Cómo quieres verificar?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Option(
            icon: Icons.mail_outline_rounded,
            title: 'Correo electrónico',
            subtitle: 'Te enviamos un código a tu correo.',
            onTap: () => Navigator.of(context).pop('EMAIL'),
          ),
          const SizedBox(height: 10),
          _Option(
            icon: Icons.phone_android_rounded,
            title: 'Aplicación autenticadora',
            subtitle: 'Usa Google Authenticator o similar.',
            onTap: () => Navigator.of(context).pop('APP'),
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

/// Opción seleccionable dentro de la ventana de verificación.
class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.anthracite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slateLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
