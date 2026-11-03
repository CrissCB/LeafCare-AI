import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leafcare_ia/app/config/app_theme.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.questionText,
    required this.actionText,
    required this.onTap,
  });

  final String questionText;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
