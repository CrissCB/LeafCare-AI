import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores del diseño de LeafCare AI.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F5132);
  static const Color primaryDark = Color(0xFF0A3320);
  static const Color primaryLight = Color(0xFF176840);
  static const Color neon = Color(0xFF00FF87);
  static const Color anthracite = Color(0xFF1E293B);
  static const Color mint = Color(0xFFE8F5E9);
  static const Color white = Color(0xFFFFFFFF);

  static const Color slate = Color(0xFF64748B);
  static const Color slateLight = Color(0xFF94A3B8);
  static const Color inputBg = Color(0xFFF8FFFE);
  static const Color inputBorder = Color(0xFFD1FAE5);
  static const Color border = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFDC2626);
  static const Color pageBg = Color(0xFFF1F5F9);

  static const Color heroStart = Color(0xFF0A3320);
  static const Color heroMid = Color(0xFF0F5132);
  static const Color heroEnd = Color(0xFF1A7A4A);

  static const Color neon12 = Color(0x1F00FF87);
  static const Color neon35 = Color(0x5900FF87);
  static const Color neon06 = Color(0x0F00FF87);
  static const Color neon05 = Color(0x0D00FF87);
}

/// Tema global de la aplicación LeafCare AI.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.anthracite,
        displayColor: AppColors.anthracite,
      ),
    );
  }
}
