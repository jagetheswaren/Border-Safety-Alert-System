import 'package:flutter/material.dart';
import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';

/// Professional dual-mode design system for BSAS.
///
/// Ensures strict visual consistency, adequate contrast, comfortable touch targets,
/// and calm civilian safety aesthetics in both Dark and Light themes.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = const ColorScheme.dark().copyWith(
      primary: BsasColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: BsasColors.darkSurface,
      onPrimaryContainer: BsasColors.textLightPrimary,
      secondary: BsasColors.radarCyan,
      onSecondary: Colors.white,
      surface: BsasColors.darkSurface,
      onSurface: BsasColors.textLightPrimary,
      surfaceContainerLowest: BsasColors.darkBackground,
      surfaceContainerLow: BsasColors.darkSurface,
      surfaceContainer: BsasColors.darkCard,
      surfaceContainerHigh: BsasColors.darkCardHover,
      outline: BsasColors.darkBorder,
      outlineVariant: BsasColors.darkBorderSubtle,
      error: BsasColors.criticalRed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: BsasColors.darkBackground,
      canvasColor: BsasColors.darkBackground,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: BsasColors.darkSurface,
        foregroundColor: BsasColors.textLightPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: BsasTypography.heading,
        iconTheme: IconThemeData(color: BsasColors.textLightPrimary, size: 22),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: BsasColors.darkCard,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.screenMargin,
          vertical: BsasSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
          side: const BorderSide(color: BsasColors.darkBorder, width: 1.0),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BsasColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, BsasSpacing.iconTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          ),
          textStyle: BsasTypography.label,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BsasColors.textLightPrimary,
          minimumSize: const Size(88, BsasSpacing.iconTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.md),
          side: const BorderSide(color: BsasColors.darkBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          ),
          textStyle: BsasTypography.label,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BsasColors.radarCyan,
          minimumSize: const Size(48, BsasSpacing.iconTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          ),
          textStyle: BsasTypography.label,
        ),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BsasColors.darkSurface,
        indicatorColor: BsasColors.primaryBlue.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BsasTypography.label.copyWith(
              fontSize: 11,
              color: BsasColors.textLightPrimary,
              fontWeight: FontWeight.w700,
            );
          }
          return BsasTypography.caption.copyWith(
            fontSize: 11,
            color: BsasColors.textLightSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: BsasColors.radarCyanGlow, size: 24);
          }
          return const IconThemeData(color: BsasColors.textLightSecondary, size: 22);
        }),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BsasColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.lg,
          vertical: BsasSpacing.md,
        ),
        hintStyle: BsasTypography.bodyMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.criticalRed),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: BsasColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: BsasColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
          side: const BorderSide(color: BsasColors.darkBorder),
        ),
      ),
    );
  }

  static ThemeData get light {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: BsasColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: BsasColors.lightBorderSubtle,
      onPrimaryContainer: BsasColors.textDarkPrimary,
      secondary: BsasColors.primaryDarkBlue,
      onSecondary: Colors.white,
      surface: BsasColors.lightSurface,
      onSurface: BsasColors.textDarkPrimary,
      surfaceContainerLowest: BsasColors.lightBackground,
      surfaceContainerLow: BsasColors.lightSurface,
      surfaceContainer: BsasColors.lightCard,
      surfaceContainerHigh: BsasColors.lightCardHover,
      outline: BsasColors.lightBorder,
      outlineVariant: BsasColors.lightBorderSubtle,
      error: BsasColors.criticalRed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: BsasColors.lightBackground,
      canvasColor: BsasColors.lightBackground,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: BsasColors.lightSurface,
        foregroundColor: BsasColors.textDarkPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BsasColors.textDarkPrimary,
        ),
        iconTheme: IconThemeData(color: BsasColors.textDarkPrimary, size: 22),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: BsasColors.lightCard,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.screenMargin,
          vertical: BsasSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
          side: const BorderSide(color: BsasColors.lightBorder, width: 1.0),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BsasColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, BsasSpacing.iconTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          ),
          textStyle: BsasTypography.label,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BsasColors.textDarkPrimary,
          minimumSize: const Size(88, BsasSpacing.iconTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.md),
          side: const BorderSide(color: BsasColors.lightBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          ),
          textStyle: BsasTypography.label,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BsasColors.primaryBlue,
          minimumSize: const Size(48, BsasSpacing.iconTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          ),
          textStyle: BsasTypography.label,
        ),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BsasColors.lightSurface,
        indicatorColor: BsasColors.primaryBlue.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BsasTypography.label.copyWith(
              fontSize: 11,
              color: BsasColors.primaryBlue,
              fontWeight: FontWeight.w700,
            );
          }
          return BsasTypography.caption.copyWith(
            fontSize: 11,
            color: BsasColors.textDarkSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: BsasColors.primaryBlue, size: 24);
          }
          return const IconThemeData(color: BsasColors.textDarkSecondary, size: 22);
        }),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BsasColors.lightCardHover,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.lg,
          vertical: BsasSpacing.md,
        ),
        hintStyle: BsasTypography.bodyMuted.copyWith(color: BsasColors.textDarkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          borderSide: const BorderSide(color: BsasColors.criticalRed),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: BsasColors.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: BsasColors.lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
          side: const BorderSide(color: BsasColors.lightBorder),
        ),
      ),
    );
  }
}
