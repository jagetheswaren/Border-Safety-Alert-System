import 'package:flutter/material.dart';

/// Centralized semantic color tokens for the BSAS civilian safety system.
///
/// Ensures strict visual consistency across mobile presentation layers.
class BsasColors {
  BsasColors._();

  // Primary Tactical Brand Palettes
  static const Color primaryBlue = Color(0xFF0EA5E9); // Sky blue
  static const Color primaryDarkBlue = Color(0xFF0284C7);
  static const Color accentNavy = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF182234);
  static const Color borderSubtle = Color(0xFF334155);

  // Modern Semantic Aliases
  static const Color darkBackground = accentNavy;
  static const Color darkSurface = surfaceDark;
  static const Color darkCard = cardDark;
  static const Color darkBorder = borderSubtle;
  static const Color radarCyan = primaryBlue;

  // Safety State Semantics
  static const Color safeGreen = Color(0xFF10B981); // Emerald safe
  static const Color safeGreenDark = Color(0xFF059669);
  static const Color cautionYellow = Color(0xFFF59E0B); // Amber caution
  static const Color warningOrange = Color(0xFFF97316); // High warning
  static const Color criticalRed = Color(0xFFEF4444); // Urgent restricted breach
  static const Color criticalRedDark = Color(0xFFDC2626);
  static const Color offlineSteel = Color(0xFF64748B); // Offline state
  static const Color unknownGrey = Color(0xFF94A3B8); // Unknown/acquiring state

  // Contrast Text Colors
  static const Color textLightPrimary = Color(0xFFF8FAFC);
  static const Color textLightSecondary = Color(0xFF94A3B8);
  static const Color textLightMuted = Color(0xFF64748B);

  static const Color textPrimary = textLightPrimary;
  static const Color textSecondary = textLightSecondary;
  static const Color textMuted = textLightMuted;

  // Helper method for resolving safety state color
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
}
