import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/alerts/presentation/bloc/alerts_bloc.dart';

/// Cabecera del Centro de Alertas con avatar decorativo y pestañas segmentadas.
class AlertsHeader extends StatelessWidget {
  const AlertsHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.selectedTab,
    required this.todayRemindersCount,
    required this.unreadIaAlertsCount,
    required this.onTabChanged,
  });

  final String userName;
  final String? avatarUrl;
  final AlertsTab selectedTab;
  final int todayRemindersCount;
  final int unreadIaAlertsCount;
  final ValueChanged<AlertsTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final remText = todayRemindersCount == 1
        ? '1 recordatorio hoy'
        : '$todayRemindersCount recordatorios hoy';
    final iaText = unreadIaAlertsCount == 1
        ? '1 alerta IA sin leer'
        : '$unreadIaAlertsCount alertas IA sin leer';

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

          // Contenido principal
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y avatar decorativo del usuario
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Centro de Alertas',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$remText · $iaText',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _DecorativeUserAvatar(
                      userName: userName,
                      avatarUrl: avatarUrl,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Selector segmentado entre Recordatorios y Alertas IA
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabPill(
                          label: 'Recordatorios',
                          count: todayRemindersCount,
                          isSelected: selectedTab == AlertsTab.reminders,
                          badgeColor: const Color(0xFFEF4444),
                          onTap: () => onTabChanged(AlertsTab.reminders),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _TabPill(
                          label: 'Alertas IA',
                          count: unreadIaAlertsCount,
                          isSelected: selectedTab == AlertsTab.iaAlerts,
                          badgeColor: AppColors.neon,
                          badgeTextColor: AppColors.primaryDark,
                          onTap: () => onTabChanged(AlertsTab.iaAlerts),
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

class _DecorativeUserAvatar extends StatelessWidget {
  const _DecorativeUserAvatar({required this.userName, this.avatarUrl});

  final String userName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'U';
    final hasImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: AppColors.neon.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _AvatarInitial(initial: initial),
            )
          : _AvatarInitial(initial: initial),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.badgeColor,
    this.badgeTextColor = AppColors.white,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color badgeColor;
  final Color badgeTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.white.withValues(alpha: 0.82),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: count > 0
                    ? badgeColor
                    : (isSelected
                          ? AppColors.slate.withValues(alpha: 0.16)
                          : AppColors.white.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: count > 0
                      ? badgeTextColor
                      : (isSelected ? AppColors.slate : AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
