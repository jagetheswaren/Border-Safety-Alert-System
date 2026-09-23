import 'package:flutter/material.dart';

/// Centralized semantic color tokens for the BSAS civilian safety system.
///
/// Designed to be calm, intentional, and human-crafted.
/// Avoids aggressive neon, glowing cards, or harsh saturated fills.
class BsasColors {
  BsasColors._();

  // Primary Civilian Safety Palette (Deep Sapphire & Cobalt)
  static const Color primaryBlue = Color(0xFF0284C7); // Sky 600
  static const Color primaryBlueLight = Color(0xFF38BDF8); // Sky 400
  static const Color primaryDarkBlue = Color(0xFF0369A1); // Sky 700

  // Neutral Scales - Dark Mode (Deep Obsidian Blue-Gray)
  static const Color darkBackground = Color(0xFF0B1320);
  static const Color darkSurface = Color(0xFF131F33);
  static const Color darkCard = Color(0xFF192942);
  static const Color darkCardHover = Color(0xFF223554);
  static const Color darkBorder = Color(0xFF283D5E);
  static const Color darkBorderSubtle = Color(0xFF1E2F48);

  // Neutral Scales - Light Mode (Crisp Polar Clean)
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEDF2F7);

  // Radar / Cyan Brand Accent
  static const Color radarCyan = Color(0xFF0284C7);
  static const Color radarCyanGlow = Color(0xFF38BDF8);

  // Safety State Semantics (Consistent, calm, dual-mode readable)
  // 1. SAFE (Level 0)
  static const Color safeGreen = Color(0xFF0D9488); // Teal/Emerald
  static const Color safeGreenDark = Color(0xFF0F766E);
  static const Color safeGreenLight = Color(0xFF14B8A6);
  static const Color safeGreenBgDark = Color(0xFF0B2E2B);
  static const Color safeGreenBgLight = Color(0xFFE6F4F1);

  // 2. CAUTION (Level 1)
  static const Color cautionYellow = Color(0xFFD97706); // Amber 600
  static const Color cautionYellowDark = Color(0xFFB45309);
  static const Color cautionYellowBgDark = Color(0xFF342308);
  static const Color cautionYellowBgLight = Color(0xFFFEF3C7);

  // 3. WARNING (Level 2)
  static const Color warningOrange = Color(0xFFEA580C); // Orange 600
  static const Color warningOrangeDark = Color(0xFFC2410C);
  static const Color warningOrangeBgDark = Color(0xFF381A08);
  static const Color warningOrangeBgLight = Color(0xFFFFEDD5);

  // 4. CRITICAL (Level 3 - Restricted Perimeter Breach)
  static const Color criticalRed = Color(0xFFDC2626); // Red 600
  static const Color criticalRedDark = Color(0xFFB91C1C);
  static const Color criticalRedBgDark = Color(0xFF3B1010);
  static const Color criticalRedBgLight = Color(0xFFFEE2E2);

  // Offline / Unknown Status
  static const Color offlineSteel = Color(0xFF64748B);
  static const Color unknownGrey = Color(0xFF94A3B8);

  // Text Colors - Dark Mode
  static const Color textLightPrimary = Color(0xFFF8FAFC);
  static const Color textLightSecondary = Color(0xFF94A3B8);
  static const Color textLightMuted = Color(0xFF64748B);

  // Text Colors - Light Mode
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF475569);
  static const Color textDarkMuted = Color(0xFF94A3B8);

  // Backwards compatible aliases
  static const Color textPrimary = textLightPrimary;
  static const Color textSecondary = textLightSecondary;
  static const Color textMuted = textLightMuted;
  static const Color borderSubtle = darkBorder;
  static const Color accentNavy = darkBackground;
  static const Color surfaceDark = darkSurface;
  static const Color cardDark = darkCard;

  /// Resolves the primary semantic color for a safety state string.
  static Color forSafetyState(String state) {
    switch (state.toUpperCase()) {
      case 'SAFE':
        return safeGreen;
      case 'CAUTION':
        return cautionYellow;
      case 'WARNING':
        return warningOrange;
      case 'CRITICAL':
      case 'INSIDE_RESTRICTED':
        return criticalRed;
      case 'OFFLINE':
        return offlineSteel;
      default:
        return unknownGrey;
    }
  }

  /// Resolves a tinted background container color for a safety state.
  static Color backgroundForState(String state, {bool isDark = true}) {
    switch (state.toUpperCase()) {
      case 'SAFE':
        return isDark ? safeGreenBgDark : safeGreenBgLight;
      case 'CAUTION':
        return isDark ? cautionYellowBgDark : cautionYellowBgLight;
      case 'WARNING':
        return isDark ? warningOrangeBgDark : warningOrangeBgLight;
      case 'CRITICAL':
      case 'INSIDE_RESTRICTED':
        return isDark ? criticalRedBgDark : criticalRedBgLight;
      default:
        return isDark ? darkSurface : lightCardHover;
    }
  }

  /// Resolves the icon representing the safety state.
  static IconData iconForState(String state) {
    switch (state.toUpperCase()) {
      case 'SAFE':
        return Icons.verified_user_outlined;
      case 'CAUTION':
        return Icons.info_outline;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CRITICAL':
      case 'INSIDE_RESTRICTED':
        return Icons.dangerous_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Theme-aware resolver helpers
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color text(bool isDark) => isDark ? textLightPrimary : textDarkPrimary;
  static Color textSec(bool isDark) => isDark ? textLightSecondary : textDarkSecondary;
  static Color textMut(bool isDark) => isDark ? textLightMuted : textDarkMuted;
}
