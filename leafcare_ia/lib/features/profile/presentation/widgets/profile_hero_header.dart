import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';

class ProfileHeroHeader extends StatelessWidget {
  const ProfileHeroHeader({
    super.key,
    required this.profile,
    this.onReturnFromSubRoute,
  });

  final UserProfileModel profile;
  final VoidCallback? onReturnFromSubRoute;

  Future<void> _pushAndNotify(BuildContext context, String route) async {
    await context.push(route);
    onReturnFromSubRoute?.call();
  }

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

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 22, 20, 24),
            child: Column(
              children: [
                // Avatar con anillo neón e insignia de proveedor
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: AppColors.neon.withValues(alpha: 0.55),
                          width: 2.2,
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
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.neon.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          profile.isGoogleAccount
                              ? Icons.g_mobiledata_rounded
                              : Icons.mail_outline_rounded,
                          size: profile.isGoogleAccount ? 20 : 14,
                          color: AppColors.neon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Nombre
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

                // Correo
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
                const SizedBox(height: 20),

                // Tarjeta translúcida con métricas interactivas
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InteractiveStat(
                          value: profile.plantsCount,
                          label: 'Plantas',
                          onTap: () => _pushAndNotify(context, '/plants'),
                        ),
                      ),
                      _StatDivider(),
                      Expanded(
                        child: _InteractiveStat(
                          value: profile.scansCount,
                          label: 'Escaneos',
                          onTap: () => _pushAndNotify(context, '/stats'),
                        ),
                      ),
                      _StatDivider(),
                      Expanded(
                        child: _InteractiveStat(
                          value: profile.alertsCount,
                          label: 'Alertas',
                          onTap: () => context.go('/alerts?tab=ia'),
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

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.white.withValues(alpha: 0.2),
    );
  }
}

class _InteractiveStat extends StatelessWidget {
  const _InteractiveStat({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Text(
              '$value',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.neon,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
