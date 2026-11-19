import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/profile/data/datasources/security_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/security_model.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/security_hero_header.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/two_factor_dialogs.dart';

/// Subpantalla "Seguridad" (`/security`).
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final SecurityDatasource _datasource = SecurityDatasource(
    supabaseClient: const AppSupabaseClient(),
  );

  SecurityModel? _security;
  bool _loading = true;
  bool _busy = false;
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
      final data = await _datasource.fetchSecurity();
      if (!mounted) return;
      setState(() {
        _security = data;
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

  Future<void> _handleTwoFactorSwitch(bool enable) async {
    final current = _security;
    if (current == null || _busy) return;

    if (!enable) {
      await _disableTwoFactor(current);
      return;
    }

    await _selectAndEnrollTwoFactor(current);
  }

  Future<void> _selectAndEnrollTwoFactor(SecurityModel current) async {
    final chosen = await ChooseTwoFactorMethodDialog.show(
      context,
      currentType: current.is2faEnabled ? current.twoFactorType : null,
    );
    if (chosen == null || !mounted) return;

    if (chosen == 'APP') {
      await _enrollTotpFlow(current);
    } else if (chosen == 'EMAIL') {
      await _enrollEmailOtpFlow(current);
    }
  }

  Future<void> _enrollTotpFlow(SecurityModel current) async {
    setState(() => _busy = true);
    try {
      final enrollment = await _datasource.startTotpEnrollment();
      if (!mounted) return;
      setState(() => _busy = false);

      final verified = await VerifyTotpEnrollmentDialog.show(
        context,
        enrollment: enrollment,
        onVerifyCode: (code) => _datasource.confirmTotpEnrollment(
          recordId: current.recordId,
          factorId: enrollment.factorId,
          code: code,
        ),
      );

      if (verified && mounted) {
        _snack('Doble autenticación con App activada');
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(
          'No se pudo iniciar la configuración de la app autenticadora.',
          error: true,
        );
      }
    }
  }

  Future<void> _enrollEmailOtpFlow(SecurityModel current) async {
    if (current.userEmail.isEmpty) {
      _snack('No se encontró un correo electrónico en tu cuenta.', error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      await _datasource.sendEmailOtpCode(current.userEmail);
      if (!mounted) return;
      setState(() => _busy = false);

      final verified = await VerifyEmailOtpDialog.show(
        context,
        email: current.userEmail,
        onVerifyCode: (code) => _datasource.confirmEmailOtpAndEnable(
          recordId: current.recordId,
          email: current.userEmail,
          code: code,
          previousTotpFactorId: current.verifiedTotpFactorId,
        ),
        onResendCode: () => _datasource.sendEmailOtpCode(current.userEmail),
      );

      if (verified && mounted) {
        _snack('Doble autenticación por correo activada');
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(
          'No se pudo enviar el código de verificación al correo.',
          error: true,
        );
      }
    }
  }

  Future<void> _disableTwoFactor(SecurityModel current) async {
    setState(() => _busy = true);
    try {
      await _datasource.disableTwoFactor(
        recordId: current.recordId,
        verifiedTotpFactorId: current.verifiedTotpFactorId,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _security = current.copyWith(
          is2faEnabled: false,
          clearTwoFactorType: true,
          clearTotpFactorId: true,
        );
      });
      _snack('Verificación en dos pasos desactivada');
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(
          'No se pudo desactivar la verificación en dos pasos.',
          error: true,
        );
      }
    }
  }

  Future<void> _openChangePassword() async {
    final updated = await ChangePasswordSheet.show(
      context,
      onSubmit: ({required currentPassword, required newPassword}) =>
          _datasource.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          ),
    );

    if (updated && mounted) {
      _snack('Contraseña actualizada correctamente');
    }
  }

  Future<void> _confirmSignOutOthers() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cerrar otras sesiones',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Se cerrará tu sesión en cualquier otro celular o navegador donde hayas iniciado sesión. Este dispositivo permanecerá conectado.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.45,
            color: AppColors.slate,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cerrar sesiones'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _datasource.signOutOtherDevices();
      if (!mounted) return;
      _snack('Se cerraron las sesiones en otros dispositivos');
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudieron cerrar las otras sesiones.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatLastSignIn(DateTime? dt) {
    if (dt == null) return 'Sin registro reciente';
    return DateFormat('dd/MM/yyyy · HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: _loading
          ? const LoadingIndicator()
          : (_error || _security == null)
          ? EmptyStateView(
              icon: Icons.gpp_bad_outlined,
              title: 'No se pudo cargar tu seguridad',
              subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
              onRetry: _load,
            )
          : _buildContent(_security!),
    );
  }

  Widget _buildContent(SecurityModel security) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SecurityHeroHeader(security: security),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Verificación en dos pasos (2FA)
                const _SectionLabel('VERIFICACIÓN EN DOS PASOS (2FA)'),
                Material(
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
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
                                    security.is2faEnabled
                                        ? 'Doble autenticación activada'
                                        : 'Activar doble autenticación',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.anthracite,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    security.is2faEnabled
                                        ? 'Método actual: ${security.twoFactorLabel}'
                                        : 'Solicita un código extra por app o correo al iniciar sesión',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: AppColors.slateLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: security.is2faEnabled,
                              onChanged: _busy ? null : _handleTwoFactorSwitch,
                              activeThumbColor: AppColors.white,
                              activeTrackColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      if (security.is2faEnabled) ...[
                        const Divider(
                          height: 1,
                          indent: 66,
                          color: AppColors.border,
                        ),
                        InkWell(
                          onTap: _busy
                              ? null
                              : () => _selectAndEnrollTwoFactor(security),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 52),
                                Expanded(
                                  child: Text(
                                    'Cambiar método de verificación',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 19,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Contraseña y acceso
                const _SectionLabel('CONTRASEÑA Y ACCESO'),
                Material(
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: security.isExternalProvider
                      ? Padding(
                          padding: const EdgeInsets.all(14),
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
                                  Icons.lock_outline_rounded,
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
                                      'Contraseña gestionada por ${security.providerLabel}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.anthracite,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Iniciaste sesión con ${security.providerLabel}, por lo que tu clave se administra desde allí.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        height: 1.35,
                                        color: AppColors.slateLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : InkWell(
                          onTap: _busy ? null : _openChangePassword,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
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
                                    Icons.lock_reset_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cambiar contraseña',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.anthracite,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Actualiza tu contraseña de acceso periódicamente',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: AppColors.slateLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.slateLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // 3. Actividad de la cuenta
                const _SectionLabel('ACTIVIDAD DE LA CUENTA'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _ActivityRow(
                        icon: Icons.access_time_rounded,
                        label: 'Último inicio de sesión',
                        value: _formatLastSignIn(security.lastSignInAt),
                      ),
                      const Divider(
                        height: 1,
                        indent: 52,
                        color: AppColors.border,
                      ),
                      _ActivityRow(
                        icon: security.isLocked
                            ? Icons.lock_clock_rounded
                            : Icons.verified_outlined,
                        label: 'Estado de la cuenta',
                        value: security.isLocked
                            ? 'Bloqueada temporalmente'
                            : 'Activa',
                        valueColor: security.isLocked
                            ? AppColors.error
                            : AppColors.primaryDark,
                      ),
                      const Divider(
                        height: 1,
                        indent: 52,
                        color: AppColors.border,
                      ),
                      _ActivityRow(
                        icon: Icons.login_rounded,
                        label: 'Intentos fallidos',
                        value: '${security.failedAttempts} / 3',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. Botón cerrar sesión en otros dispositivos
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _confirmSignOutOthers,
                    icon: const Icon(Icons.devices_other_rounded, size: 19),
                    label: const Text('Cerrar sesión en otros dispositivos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      backgroundColor: AppColors.white,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
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
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.slate,
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.anthracite,
            ),
          ),
        ],
      ),
    );
  }
}
