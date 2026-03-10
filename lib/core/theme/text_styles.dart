import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class NavJeevanTextStyles {
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: NavJeevanColors.textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  static TextStyle get headlineMedium => GoogleFonts.cormorantGaramond(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: NavJeevanColors.textDark,
  );

  static TextStyle get titleLarge => GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: NavJeevanColors.textDark,
  );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: NavJeevanColors.textDark,
  );

  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: NavJeevanColors.textSoft,
  );

  static TextStyle get labelLarge => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: NavJeevanColors.pureWhite,
  );
}
