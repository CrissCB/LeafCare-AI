import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:leafcare_ia/features/profile/data/datasources/profile_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/profile_hero_header.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/profile_menu_group.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileDatasource _datasource = ProfileDatasource(
    supabaseClient: const AppSupabaseClient(),
  );

  late Future<UserProfileModel> _profileFuture;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _datasource.fetchProfile();
  }

  void _reload() {
    setState(() {
      _profileFuture = _datasource.fetchProfile();
    });
  }

  Future<void> _pushAndRefresh(String route) async {
    await context.push(route);
    if (mounted) _reload();
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      context.read<AuthBloc>().add(LogoutRequestedEvent());
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await DeleteAccountDialog.show(context);
    if (!confirmed || !mounted) return;

    setState(() => _isDeletingAccount = true);

    try {
      await _datasource.deleteOwnAccount();
      if (mounted) {
        context.read<AuthBloc>().add(LogoutRequestedEvent());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        _snack(
          'No se pudo eliminar la cuenta. Inténtalo de nuevo.',
          isError: true,
        );
      }
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
                SliverToBoxAdapter(
                  child: ProfileHeroHeader(
                    profile: profile,
                    onReturnFromSubRoute: _reload,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grupo 1: Mi cuenta y preferencias
                        ProfileMenuGroup(
                          sectionTitle: 'Mi cuenta y preferencias',
                          items: [
                            ProfileMenuItemData(
                              icon: Icons.person_outline_rounded,
                              label: 'Mi cuenta',
                              subtitle: 'Avatar, nombre y datos de acceso',
                              onTap: () => _pushAndRefresh('/account'),
                            ),
                            ProfileMenuItemData(
                              icon: Icons.notifications_none_rounded,
                              label: 'Notificaciones',
                              subtitle: 'Avisos push y resúmenes por correo',
                              onTap: () => _pushAndRefresh('/notifications'),
                            ),
                          ],
                        ),

                        // Grupo 2: Seguridad y analítica
                        ProfileMenuGroup(
                          sectionTitle: 'Seguridad y analítica',
                          items: [
                            ProfileMenuItemData(
                              icon: Icons.shield_outlined,
                              label: 'Seguridad',
                              subtitle: 'Contraseña, 2FA y sesiones activas',
                              onTap: () => _pushAndRefresh('/security'),
                            ),
                            ProfileMenuItemData(
                              icon: Icons.bar_chart_rounded,
                              label: 'Estadísticas',
                              subtitle: 'Salud del jardín e historial IA',
                              badgeText: 'Ver resumen',
                              onTap: () => _pushAndRefresh('/stats'),
                            ),
                          ],
                        ),

                        // Grupo 3: Soporte e información
                        ProfileMenuGroup(
                          sectionTitle: 'Soporte e información',
                          items: [
                            ProfileMenuItemData(
                              icon: Icons.help_outline_rounded,
                              label: 'Ayuda y LeafCare AI',
                              subtitle:
                                  'Manual, contacto, términos y versión 1.0.0',
                              onTap: () => _pushAndRefresh('/help?tab=support'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Botón de Cerrar sesión
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isDeletingAccount
                                ? null
                                : _confirmLogout,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Cerrar sesión'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              backgroundColor: AppColors.white,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Acción secundaria: Eliminar cuenta
                        Center(
                          child: TextButton(
                            onPressed: _isDeletingAccount
                                ? null
                                : _confirmDeleteAccount,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.slateLight,
                            ),
                            child: _isDeletingAccount
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.error,
                                    ),
                                  )
                                : Text(
                                    'Eliminar mi cuenta permanentemente',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Pie de página
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
