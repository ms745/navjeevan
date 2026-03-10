import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class NavJeevanTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NavJeevanColors.primaryRose,
      brightness: Brightness.light,
      primary: NavJeevanColors.primaryRose,
      secondary: NavJeevanColors.roseLight,
      surface: NavJeevanColors.pureWhite,
      background: NavJeevanColors.petalLight,
    ),
    scaffoldBackgroundColor: NavJeevanColors.petalLight,
    appBarTheme: AppBarTheme(
      backgroundColor: NavJeevanColors.pureWhite,
      foregroundColor: NavJeevanColors.textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: NavJeevanTextStyles.headlineMedium.copyWith(fontSize: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NavJeevanColors.primaryRose,
        foregroundColor: NavJeevanColors.pureWhite,
        elevation: 4,
        shadowColor: NavJeevanColors.primaryRose.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        minimumSize: const Size(double.infinity, 56),
        textStyle: NavJeevanTextStyles.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NavJeevanColors.pureWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NavJeevanColors.borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NavJeevanColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NavJeevanColors.primaryRose, width: 2),
      ),
      labelStyle: TextStyle(color: NavJeevanColors.textSoft),
      floatingLabelStyle: const TextStyle(color: NavJeevanColors.primaryRose, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: NavJeevanColors.pureWhite,
      elevation: 2,
      shadowColor: NavJeevanColors.primaryRose.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
    ),
    textTheme: TextTheme(
      displayLarge: NavJeevanTextStyles.displayLarge,
      headlineMedium: NavJeevanTextStyles.headlineMedium,
      titleLarge: NavJeevanTextStyles.titleLarge,
      bodyLarge: NavJeevanTextStyles.bodyLarge,
      bodySmall: NavJeevanTextStyles.bodySmall,
      labelLarge: NavJeevanTextStyles.labelLarge,
    ),
  );
}
