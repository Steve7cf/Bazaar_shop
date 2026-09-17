import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppRadius {
  AppRadius._();
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppPalette.light);
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: palette.bgPrimary,
      fontFamily: 'SF Pro',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.accent,
        onPrimary: Colors.white,
        secondary: palette.accentLight,
        onSecondary: Colors.white,
        error: palette.danger,
        onError: Colors.white,
        surface: palette.bgSecondary,
        onSurface: palette.textPrimary,
      ),
      extensions: [palette],
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: palette.textPrimary,
            displayColor: palette.textPrimary,
          )
          .copyWith(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: palette.textPrimary,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: palette.textPrimary,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            titleMedium: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            bodyLarge: TextStyle(fontSize: 16, color: palette.textPrimary),
            bodyMedium: TextStyle(fontSize: 14, color: palette.textSecondary),
            bodySmall: TextStyle(fontSize: 12, color: palette.textTertiary),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: palette.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: palette.border, width: isDark ? 1 : 0),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.bgTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.danger),
        ),
        hintStyle: TextStyle(color: palette.textTertiary),
        labelStyle: TextStyle(color: palette.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.textTertiary.withValues(
            alpha: 0.3,
          ),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.sidebar,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.textTertiary.withValues(
          alpha: isDark ? 0.7 : 0.6,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: palette.sidebar),
    );
  }

  /// Soft shadow in light mode, glow-accent shadow in dark mode — per spec.
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: AppColors.darkAccent.withValues(alpha: 0.12),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
