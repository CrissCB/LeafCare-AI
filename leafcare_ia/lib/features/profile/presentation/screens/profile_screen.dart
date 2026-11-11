import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:leafcare_ia/features/profile/data/datasources/profile_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';

/// Pantalla de perfil del usuario.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileDatasource _datasource = ProfileDatasource();
  late Future<UserProfileModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _datasource.fetchProfile();
  }

  /// Vuelve a pedir los datos al servidor.
  void _reload() {
    setState(() {
      _profileFuture = _datasource.fetchProfile();
    });
  }

  /// Pregunta antes de cerrar la sesión.
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Seguro que quieres salir de tu cuenta?',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // El router escucha este evento y nos manda al login automáticamente.
      context.read<AuthBloc>().add(LogoutRequestedEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: FutureBuilder<UserProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return EmptyStateView(
              icon: Icons.person_off_rounded,
              title: 'No se pudo cargar tu perfil',
              subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
              onRetry: _reload,
            );
          }

          final profile = snapshot.data!;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _reload();
              await _profileFuture;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MenuTile(
                          icon: Icons.local_florist_outlined,
                          label: 'Mis plantas',
                          subtitle: 'Todas tus plantas y su historial',
                          onTap: () => context.push('/plants'),
                        ),
                        _MenuTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Mi cuenta',
                          subtitle: 'Nombre, correo y contraseña',
                          onTap: () => context.push('/account'),
                        ),
                        _MenuTile(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notificaciones',
                          subtitle: 'Avisos y resumen por correo',
                          onTap: () => context.push('/notifications'),
                        ),
                        _MenuTile(
                          icon: Icons.shield_outlined,
                          label: 'Seguridad',
                          subtitle: 'Verificación en dos pasos',
                          onTap: () => context.push('/security'),
                        ),
                        _MenuTile(
                          icon: Icons.bar_chart_rounded,
                          label: 'Estadísticas',
                          subtitle: 'Resumen del cuidado de tus plantas',
                          onTap: () => context.push('/stats'),
                        ),
                        _MenuTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Ayuda y soporte',
                          subtitle: 'Preguntas frecuentes y contacto',
                          onTap: () => context.push('/help'),
                        ),
                        _MenuTile(
                          icon: Icons.info_outline_rounded,
                          label: 'Acerca de LeafCare AI',
                          subtitle: 'Versión 1.0.0',
                          onTap: () => context.push('/about'),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _confirmLogout,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Cerrar sesión'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(
                                color: AppColors.error,
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'LeafCare AI · Hecho con Flutter',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.slateLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Encabezado verde con la foto, el nombre y los contadores.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 24,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Foto de perfil o la inicial del nombre
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: profile.avatarUrl.isNotEmpty
                ? Image.network(
                    profile.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initialAvatar(),
                  )
                : _initialAvatar(),
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          if (profile.email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              profile.email,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Cuenta con ${profile.providerLabel}',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Contadores
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  value: profile.plantsCount,
                  label: 'Plantas',
                ),
              ),
              _Divider(),
              Expanded(
                child: _HeaderStat(
                  value: profile.scansCount,
                  label: 'Escaneos',
                ),
              ),
              _Divider(),
              Expanded(
                child: _HeaderStat(
                  value: profile.alertsCount,
                  label: 'Alertas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar() {
    return Center(
      child: Text(
        profile.initial,
        style: GoogleFonts.outfit(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Línea vertical separadora entre contadores.
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.white.withValues(alpha: 0.18),
    );
  }
}

/// Número grande con su etiqueta debajo.
class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.white.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}

/// Opción del menú del perfil.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
                    label,
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
                      fontSize: 11,
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
    );
  }
}
