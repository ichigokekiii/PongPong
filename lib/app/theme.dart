import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFFF6F1E8);
  const canvas = Color(0xFFFFFBF5);
  const ink = Color(0xFF11212D);
  const accent = Color(0xFFEE6C4D);
  const secondary = Color(0xFF2A9D8F);
  const highlight = Color(0xFFF4A261);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.light,
    primary: ink,
    secondary: secondary,
    surface: canvas,
  );

  final baseText = GoogleFonts.spaceGroteskTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    textTheme: baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(color: ink),
      bodyMedium: baseText.bodyMedium?.copyWith(
        color: ink.withValues(alpha: 0.78),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: highlight.withValues(alpha: 0.16),
      selectedColor: accent.withValues(alpha: 0.18),
      side: BorderSide.none,
      labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    cardTheme: CardThemeData(
      color: canvas.withValues(alpha: 0.9),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: ink.withValues(alpha: 0.16)),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: secondary,
      linearTrackColor: Color(0xFFDCE8E5),
    ),
  );
}
