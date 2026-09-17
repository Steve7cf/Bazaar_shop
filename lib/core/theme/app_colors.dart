import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AppColors {
  AppColors._();

  // Light theme
  static const lightAccent = Color(0xFF007AFF);
  static const lightAccentDark = Color(0xFF0060DF);
  static const lightAccentLight = Color(0xFF3395FF);

  static const lightBgPrimary = Color(0xFFF5F5F7);
  static const lightBgSecondary = Color(0xFFFFFFFF);
  static const lightBgTertiary = Color(0xFFFAFAFA);
  static const lightSidebar = Color(0xFF1C1C1E);

  static const lightTextPrimary = Color(0xFF1D1D1F);
  static const lightTextSecondary = Color(0xFF6E6E73);
  static const lightTextTertiary = Color(0xFF86868B);

  static const lightBorder = Color(0xFFE5E5EA);

  static const lightSuccess = Color(0xFF1E6B33);
  static const lightWarning = Color(0xFF9A5B00);
  static const lightDanger = Color(0xFFD70015);

  // Dark theme
  static const darkAccent = Color(0xFF0A84FF);
  static const darkAccentDark = Color(0xFF0868C7);
  static const darkAccentLight = Color(0xFF409CFF);

  static const darkBgPrimary = Color(0xFF000000);
  static const darkBgSecondary = Color(0xFF1C1C1E);
  static const darkBgTertiary = Color(0xFF2C2C2E);
  static const darkSidebar = Color(0xFF0A0A0B);

  static const darkTextPrimary = Color(0xFFF5F5F7);
  static const darkTextSecondary = Color(0xFFAEAEB2);
  static const darkTextTertiary = Color(0xFF98989D);

  static const darkBorder = Color(0x17FFFFFF); // rgba(255,255,255,0.09)

  static const darkSuccess = Color(0xFF34C759);
  static const darkWarning = Color(0xFFFF9F0A);
  static const darkDanger = Color(0xFFFF3B30);
}

/// Semantic accessor so widgets don't branch on Brightness everywhere.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color accent;
  final Color accentDark;
  final Color accentLight;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color sidebar;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;

  const AppPalette({
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.sidebar,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
  });

  static const light = AppPalette(
    accent: AppColors.lightAccent,
    accentDark: AppColors.lightAccentDark,
    accentLight: AppColors.lightAccentLight,
    bgPrimary: AppColors.lightBgPrimary,
    bgSecondary: AppColors.lightBgSecondary,
    bgTertiary: AppColors.lightBgTertiary,
    sidebar: AppColors.lightSidebar,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    border: AppColors.lightBorder,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    danger: AppColors.lightDanger,
  );

  static const dark = AppPalette(
    accent: AppColors.darkAccent,
    accentDark: AppColors.darkAccentDark,
    accentLight: AppColors.darkAccentLight,
    bgPrimary: AppColors.darkBgPrimary,
    bgSecondary: AppColors.darkBgSecondary,
    bgTertiary: AppColors.darkBgTertiary,
    sidebar: AppColors.darkSidebar,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    border: AppColors.darkBorder,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    danger: AppColors.darkDanger,
  );

  @override
  AppPalette copyWith({
    Color? accent,
    Color? accentDark,
    Color? accentLight,
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? sidebar,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppPalette(
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      accentLight: accentLight ?? this.accentLight,
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      sidebar: sidebar ?? this.sidebar,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgTertiary, other.bgTertiary, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
