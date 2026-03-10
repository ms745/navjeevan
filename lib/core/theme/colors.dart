import 'package:flutter/material.dart';

class NavJeevanColors {
  static const primaryRose   = Color(0xFFF4436C);
  static const roseLight     = Color(0xFFFF7096);
  static const deepRose      = Color(0xFFC4214A);
  static const blush         = Color(0xFFFFD6E0);
  static const petalLight    = Color(0xFFFFF0F4);
  static const dustyPink     = Color(0xFFE8A0B4);
  static const pureWhite     = Color(0xFFFFFFFF);
  static const offWhite      = Color(0xFFFFF8FA);
  static const textDark      = Color(0xFF2D1B22);
  static const textMid       = Color(0xFF6B3A4D);
  static const textSoft      = Color(0xFF9C6A7A);
  static const borderColor   = Color(0xFFF7C5D3);
  static const successGreen  = Color(0xFF28A745);
  static const warningOrange = Color(0xFFFF8C42);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [primaryRose, roseLight],
  );

  static const bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
    colors: [Color(0xFFFFF0F4), pureWhite],
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFE4EC), Color(0xFFFFF8FA)],
  );
}
