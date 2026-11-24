import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';

/// Cabecera hero de la subpantalla Mi cuenta con avatar editable e insignia de proveedor.
class AccountHeroHeader extends StatelessWidget {
  const AccountHeroHeader({
    super.key,
    required this.profile,
    this.previewAvatarBytes,
    this.onPickAvatar,
  });

  final UserProfileModel profile;
  final Uint8List? previewAvatarBytes;
  final VoidCallback? onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final canEdit = !profile.isGoogleAccount && onPickAvatar != null;

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
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 26),
            child: Column(
              children: [
                // Barra superior de navegación
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
                            'Mi cuenta',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'Identidad y método de registro',
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
                const SizedBox(height: 22),

                // Avatar central de 96x96 con anillo neón
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: canEdit ? onPickAvatar : null,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: AppColors.neon.withValues(alpha: 0.6),
                            width: 2.4,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildAvatarContent(),
                      ),
                    ),
                    if (canEdit)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: GestureDetector(
                          onTap: onPickAvatar,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.neon,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryDark,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 17,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Insignia que representa con qué se registró el usuario
                _ProviderRegistrationBadge(
                  isGoogleAccount: profile.isGoogleAccount,
                  providerLabel: profile.providerLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (previewAvatarBytes != null) {
      return Image.memory(previewAvatarBytes!, fit: BoxFit.cover);
    }
    if (profile.avatarUrl.isNotEmpty) {
      return Image.network(
        profile.avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialAvatar(),
      );
    }
    return _initialAvatar();
  }

  Widget _initialAvatar() {
    return Center(
      child: Text(
        profile.initial,
        style: GoogleFonts.outfit(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _ProviderRegistrationBadge extends StatelessWidget {
  const _ProviderRegistrationBadge({
    required this.isGoogleAccount,
    required this.providerLabel,
  });

  final bool isGoogleAccount;
  final String providerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.neon.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGoogleAccount
                ? Icons.g_mobiledata_rounded
                : Icons.mark_email_read_outlined,
            size: isGoogleAccount ? 20 : 15,
            color: AppColors.neon,
          ),
          const SizedBox(width: 6),
          Text(
            isGoogleAccount
                ? 'Registrado con Google'
                : 'Registrado con $providerLabel',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner informativo mostrado únicamente cuando la cuenta es de Google.
class GoogleManagedAccountBanner extends StatelessWidget {
  const GoogleManagedAccountBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil sincronizado con Google',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu foto de perfil, nombre y correo se obtienen directamente de tu cuenta de Google y no se modifican desde aquí.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.anthracite,
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
