import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/profile/data/datasources/notifications_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/notification_settings_model.dart';

/// Subpantalla de configuración de notificaciones (`/notifications`).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsDatasource _datasource = NotificationsDatasource(
    supabaseClient: const AppSupabaseClient(),
  );

  NotificationSettingsModel? _settings;
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
      final settings = await _datasource.fetchSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
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

  /// Actualización optimista inmediata en `public.profiles` con reversión ante fallo.
  Future<void> _save(NotificationSettingsModel next) async {
    if (_saving) return;
    final previous = _settings;

    setState(() {
      _settings = next;
      _saving = true;
    });

    try {
      await _datasource.updateSettings(next);
      if (!mounted) return;
      _snack('Preferencias actualizadas');
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = previous);
      _snack(
        'No se pudo guardar la preferencia. Revisa tu conexión.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: _loading
          ? const LoadingIndicator()
          : (_error || _settings == null)
          ? EmptyStateView(
              icon: Icons.notifications_off_outlined,
              title: 'No se pudieron cargar las preferencias',
              subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
              onRetry: _load,
            )
          : _buildContent(_settings!),
    );
  }

  Widget _buildContent(NotificationSettingsModel settings) {
    final activeCount = settings.activeCount;
    final statusTitle = activeCount == 0
        ? 'Notificaciones pausadas'
        : activeCount == 1
        ? '1 canal de aviso activo'
        : '$activeCount canales de aviso activos';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera Hero degradada con tarjeta translúcida de estado
          _NotificationsHeroHeader(
            activeCount: activeCount,
            statusTitle: statusTitle,
            isSaving: _saving,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Bloque: En este dispositivo
                const _SectionLabel(title: 'EN ESTE DISPOSITIVO'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _NotificationSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notificaciones push',
                    subtitle: 'Avisos en el celular para recordatorios de cuidado y alertas críticas de IA',
                    value: settings.pushEnabled,
                    enabled: !_saving,
                    onChanged: (val) =>
                        _save(settings.copyWith(pushEnabled: val)),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Bloque: Resúmenes por correo agrupados
                const _SectionLabel(title: 'RESÚMENES POR CORREO'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _NotificationSwitchTile(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Resumen diario',
                        subtitle: 'Recibe cada día los cuidados programados y alertas pendientes',
                        value: settings.dailyEmailSummary,
                        enabled: !_saving,
                        onChanged: (val) =>
                            _save(settings.copyWith(dailyEmailSummary: val)),
                      ),
                      const Divider(
                        height: 1,
                        indent: 66,
                        endIndent: 14,
                        color: AppColors.border,
                      ),
                      _NotificationSwitchTile(
                        icon: Icons.calendar_month_outlined,
                        title: 'Resumen semanal',
                        subtitle: 'Balance semanal de salud, escaneos realizados y cumplimiento',
                        value: settings.weeklyEmailSummary,
                        enabled: !_saving,
                        onChanged: (val) =>
                            _save(settings.copyWith(weeklyEmailSummary: val)),
                      ),
                    ],
                  ),
                ),

                // 4. Nota con el correo destino real
                if (settings.userEmail.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 19,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.anthracite,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Los resúmenes se enviarán a ',
                                ),
                                TextSpan(
                                  text: settings.userEmail,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHeroHeader extends StatelessWidget {
  const _NotificationsHeroHeader({
    required this.activeCount,
    required this.statusTitle,
    required this.isSaving,
  });

  final int activeCount;
  final String statusTitle;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -45,
            right: -35,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notificaciones',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'Alertas en el móvil y reportes por correo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Tarjeta translúcida de estado general
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: activeCount > 0
                              ? AppColors.neon.withValues(alpha: 0.16)
                              : AppColors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          activeCount > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_paused_outlined,
                          color: activeCount > 0
                              ? AppColors.neon
                              : AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              isSaving
                                  ? 'Sincronizando preferencias...'
                                  : 'Los cambios se guardan automáticamente',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSaving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neon,
                          ),
                        ),
                    ],
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
  const _SectionLabel({required this.title});

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

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
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
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.anthracite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.slateLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: AppColors.white,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
