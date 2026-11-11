import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';
import 'package:leafcare_ia/features/profile/data/datasources/notifications_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/notification_settings_model.dart';

/// Pantalla "Notificaciones": activa o desactiva los avisos.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsDatasource _datasource = NotificationsDatasource();

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

  /// Guarda el cambio y, si falla, deja la opción como estaba.
  Future<void> _save(NotificationSettingsModel next) async {
    final previous = _settings;

    setState(() {
      _settings = next;
      _saving = true;
    });

    try {
      await _datasource.updateSettings(next);
      if (!mounted) return;
      _snack('Preferencias guardadas');
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = previous);
      _snack('No se pudieron guardar los cambios', error: true);
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
            title: 'Notificaciones',
            subtitle: 'Elige cómo quieres recibir los avisos de tus plantas.',
            icon: Icons.notifications_none_rounded,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingIndicator();

    if (_error || _settings == null) {
      return EmptyStateView(
        icon: Icons.wifi_off_rounded,
        title: 'No se pudieron cargar tus avisos',
        subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
        onRetry: _load,
      );
    }

    final settings = _settings!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        // Aviso informativo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Los avisos te recuerdan regar, abonar o revisar tus plantas. '
                  'Puedes cambiarlos cuando quieras.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SwitchCard(
          icon: Icons.notifications_active_outlined,
          title: 'Avisos en la aplicación',
          subtitle: 'Recibe alertas mientras usas LeafCare AI.',
          value: settings.pushEnabled,
          enabled: !_saving,
          onChanged: (value) =>
              _save(settings.copyWith(pushEnabled: value)),
        ),
        const SizedBox(height: 10),
        _SwitchCard(
          icon: Icons.wb_sunny_outlined,
          title: 'Resumen diario por correo',
          subtitle: 'Un correo cada día con los cuidados pendientes.',
          value: settings.dailyEmail,
          enabled: !_saving,
          onChanged: (value) =>
              _save(settings.copyWith(dailyEmail: value)),
        ),
        const SizedBox(height: 10),
        _SwitchCard(
          icon: Icons.calendar_month_outlined,
          title: 'Resumen semanal por correo',
          subtitle: 'Un correo a la semana con el estado de tus plantas.',
          value: settings.weeklyEmail,
          enabled: !_saving,
          onChanged: (value) =>
              _save(settings.copyWith(weeklyEmail: value)),
        ),
        if (_saving) ...[
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Guardando...',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.slateLight,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta con un interruptor para una preferencia.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
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
    return Container(
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.slateLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
