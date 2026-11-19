import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';

class ProfileMenuItemData {
  const ProfileMenuItemData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeText;
}

class ProfileMenuGroup extends StatelessWidget {
  const ProfileMenuGroup({
    super.key,
    required this.sectionTitle,
    required this.items,
  });

  final String sectionTitle;
  final List<ProfileMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              sectionTitle.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.slate,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _GroupedTile(item: items[i]),
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 66,
                      endIndent: 14,
                      color: AppColors.border,
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

class _GroupedTile extends StatelessWidget {
  const _GroupedTile({required this.item});

  final ProfileMenuItemData item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.anthracite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.slateLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.badgeText!,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.slateLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
