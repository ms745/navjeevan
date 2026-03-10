import 'package:flutter/material.dart';

class ParentThemeColors {
  // Primary Blue shades with gradient & shine effect
  static const primaryBlue = Color(0xFF2563EB); // Trust Blue
  static const blueLight = Color(0xFF60A5FA);
  static const deepBlue = Color(0xFF1E40AF);
  static const skyBlue = Color(0xFFE0F0FF); // From design
  static const iceBlue = Color(0xFFF0F9FF);
  static const shimmerBlue = Color(0xFFDEEBFF);

  // Secondary Pink shades (for adoption warmth)
  static const accentPink = Color(0xFFFCE4EC);
  static const pinkSoft = Color(0xFFFBDAE8);
  static const pinkDark = Color(0xFFF472B6);

  // Neutral & Text colors
  static const pureWhite = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF8FAFC);
  static const backgroundLight = Color(0xFFF5F7F8);
  static const textDark = Color(0xFF1E293B);
  static const textMid = Color(0xFF475569);
  static const textSoft = Color(0xFF94A3B8);
  static const borderColor = Color(0xFFCBD5E1);

  // Status colors
  static const successGreen = Color(0xFF10B981);
  static const warningOrange = Color(0xFFF59E0B);
  static const errorRed = Color(0xFFEF4444);
  static const infoBlue = Color(0xFF3B82F6);

  // Trust gradients (blues with subtle shine)
  static const trustGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  );

  static const lightTrustGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDEEBFF), Color(0xFFE0F0FF)],
  );

  static const bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE0F0FF), // skyBlue
      Color(0xFFFFFFFF), // pureWhite
    ],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0F9FF), // iceBlue
      Color(0xFFFFFFFF), // pureWhite
    ],
  );

  // Shimmer effect gradient for trust indicators
  static const shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDEEBFF), Color(0xFFBFDBFE), Color(0xFFDEEBFF)],
  );

  // Blue-Pink blend for adoption warmth with trust
  static const adoptionWarmthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF60A5FA), // blueLight
      Color(0xFFF472B6), // pinkDark
    ],
  );
}
