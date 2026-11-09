import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';

/// Encabezado verde de la pantalla principal.
///
/// Muestra el saludo al usuario y tres contadores: plantas, alertas y riegos.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.plantsCount,
    required this.alertsCount,
    required this.remindersCount,
  });

  final String userName;
  final int plantsCount;
  final int alertsCount;
  final int remindersCount;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior: logo, nombre de la app y campanita
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
              // Acceso directo a la pantalla de estadísticas
              Tooltip(
                message: 'Ver estadísticas',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/stats'),
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
              const SizedBox(width: 8),
              _NotificationBell(count: alertsCount),
            ],
          ),
          const SizedBox(height: 22),

          // Saludo personalizado
          Text(
            'Hola, $userName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Así están tus plantas hoy',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 20),

          // Contadores rápidos
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.eco_rounded,
                  value: plantsCount,
                  label: 'Plantas',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.notifications_rounded,
                  value: alertsCount,
                  label: 'Alertas',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.water_drop_rounded,
                  value: remindersCount,
                  label: 'Riegos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Campanita con un punto rojo cuando hay alertas sin leer.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.white,
            size: 22,
          ),
          if (count > 0)
            Positioned(
              top: 9,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.neon,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta pequeña con un número y su etiqueta.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.neon, size: 20),
          const SizedBox(height: 6),
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
      ),
    );
  }
}
