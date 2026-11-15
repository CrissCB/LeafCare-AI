import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';

/// Encabezado verde de la pantalla principal.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.alertsCount,
    this.onNavigateReturn,
  });

  final String userName;
  final String? avatarUrl;
  final int alertsCount;
  final VoidCallback? onNavigateReturn;

  Future<void> _goTo(BuildContext context, String route) async {
    await context.push(route);
    onNavigateReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
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
          // Círculo decorativo superior derecho
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

          // Círculo decorativo inferior izquierdo
          Positioned(
            bottom: -55,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Contenido principal de la cabecera
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra superior: logo, nombre de la app y accesos rápidos
                Row(
                  children: [
                    const LeafLogo(size: 32),
                    const SizedBox(width: 10),
                    Text(
                      'LeafCare AI',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Ver estadísticas',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _goTo(context, '/stats'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _NotificationBell(
                      count: alertsCount,
                      onTap: () => _goTo(context, '/alerts'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bloque de saludo: avatar circular + bienvenida + ¡Hola, nombre! + ícono
                Row(
                  children: [
                    _UserAvatar(userName: userName, avatarUrl: avatarUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido de vuelta',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.78),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '¡Hola, $userName!',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.eco_rounded,
                                color: AppColors.neon,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar circular con borde sutil o inicial de respaldo.
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.userName, this.avatarUrl});

  final String userName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'U';
    final hasImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.16),
        border: Border.all(
          color: AppColors.neon.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _AvatarFallback(initial: initial),
            )
          : _AvatarFallback(initial: initial),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Botón de notificaciones con insignia numérica cuando hay alertas pendientes.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeText = count > 99 ? '99+' : '$count';

    return Tooltip(
      message: count > 0
          ? '$count alertas sin leer'
          : 'Alertas y recordatorios',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.white,
                size: 22,
              ),
              if (count > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neon,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.heroMid, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        badgeText,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
