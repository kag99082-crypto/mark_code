import 'package:flutter/material.dart';

class AppTheme {
  static const bg          = Color(0xFF070A14);
  static const surface     = Color(0xFF111624);
  static const surfaceAlt  = Color(0xFF1A2030);
  static const surfaceHigh = Color(0xFF232B3E);
  static const primary     = Color(0xFF7B7CFF);
  static const secondary   = Color(0xFF00E0B8);
  static const accent      = Color(0xFFFF6B9D);
  static const warn        = Color(0xFFFFB347);
  static const textPrimary = Color(0xFFF0F2FA);
  static const textSecondary = Color(0xFF8B93AB);
  static const textMuted   = Color(0xFF5A6278);

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: accent,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: textPrimary),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: textMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surfaceHigh,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.5)),
      hintStyle: const TextStyle(color: textMuted),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.06), thickness: 1),
  );
}
