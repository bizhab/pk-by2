import 'package:flutter/material.dart';

class AppColors {
  static const primary    = Color(0xFF346739);
  static const secondary  = Color(0xFF79AE6F);
  static const accent     = Color(0xFF9FCB98);
  static const background = Color(0xFFF2EDC2);
  static const surface    = Color(0xFFFFFFFF);
  static const cardBg     = Color(0xFFFAF8EE);
  static const error      = Color(0xFFD32F2F);
  static const textDark   = Color(0xFF1A2E1B);
  static const textMid    = Color(0xFF4A6B4C);
  static const textLight  = Color(0xFF8AAB8C);
  static const divider    = Color(0xFFDDD8A8);

  // Stat card gradients
  static const gradSantri   = [Color(0xFF346739), Color(0xFF5A9E5F)];
  static const gradDosen    = [Color(0xFF2E6B8A), Color(0xFF4A9BBF)];
  static const gradPembina  = [Color(0xFF8A5E2E), Color(0xFFBF924A)];
  static const gradSP       = [Color(0xFF8A2E2E), Color(0xFFBF4A4A)];
  static const gradHadir    = [Color(0xFF2E7A6B), Color(0xFF4ABFAD)];
}

// Fast Text Styles - No GoogleFonts runtime overhead
class AppTextStyles {
  // Playfair Display
  static const displayLarge = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle appBarTitle = const TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const sidebarTitle = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // Plus Jakarta Sans - Headlines
  static const headlineMedium = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const headlineSmall = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  // Plus Jakarta Sans - Titles
  static const titleLarge = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const titleMedium = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const titleSmall = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // Plus Jakarta Sans - Body
  static const bodyLarge = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 16,
    color: AppColors.textMid,
  );

  static const bodyMedium = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 14,
    color: AppColors.textMid,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 12,
    color: AppColors.textMid,
  );

  // Plus Jakarta Sans - Labels
  static const labelLarge = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 12,
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
  );

  static const labelMedium = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 12,
    color: AppColors.textLight,
    fontWeight: FontWeight.w500,
  );

  static const labelSmall = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 11,
    color: AppColors.textLight,
    letterSpacing: 0.8,
  );

  static const buttonText = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w600,
  );

  static const chipLabel = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 12,
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: AppTextStyles.appBarTitle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: AppTextStyles.buttonText,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textMid),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
      labelStyle: AppTextStyles.chipLabel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: Colors.transparent),
    ),
  );
}
