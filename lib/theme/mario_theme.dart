import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PhonePong Mario-inspired design tokens.
///
/// Single source of truth for every color, shadow, radius, and spacing value
/// used across the app. Components must never hardcode a hex value — pull from
/// here so theming + dark-mode + high-contrast remain trivial to swap.
class MarioColors {
  const MarioColors._();

  // --- Game-state semantic colors ------------------------------------------
  /// Ball is far — red. Player should NOT swing.
  static const Color stateFar = Color(0xFFE52521);

  /// Ball is near — coin gold. Player should get ready.
  static const Color stateNear = Color(0xFFFBD000);

  /// Ball is in hit zone — pipe green. SWING NOW.
  static const Color stateReady = Color(0xFF00A651);

  // --- Brand & surfaces -----------------------------------------------------
  static const Color sky = Color(0xFF5C94FC);
  static const Color marioBlue = Color(0xFF049CD8);
  static const Color marioRed = Color(0xFFE52521);
  static const Color coin = Color(0xFFFBD000);
  static const Color luigiGreen = Color(0xFF43B047);
  static const Color pipe = Color(0xFF00A651);
  static const Color brick = Color(0xFFC84C0C);
  static const Color brickDark = Color(0xFF8B3508);
  static const Color cloudWhite = Color(0xFFFFFFFF);
  static const Color bowserBlack = Color(0xFF000000);
  static const Color shadow = Color(0xFF222222);

  // --- Hit / Miss / Smash event flashes -------------------------------------
  static const Color hitFlash = Color(0xFFFFFFFF);
  static const Color smashFlash = Color(0xFFFBD000);
  static const Color missFlash = Color(0xFFE52521);
}

class MarioSpacing {
  const MarioSpacing._();

  /// 4 / 8 / 16 / 24 / 32 / 48 / 64 — constrained scale.
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;
}

class MarioRadius {
  const MarioRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

/// Sharp arcade motion durations (per user preference).
class MarioMotion {
  const MarioMotion._();

  /// One blink half-cycle. 80 ms = 6.25 Hz "fast arcade" flicker.
  static const Duration blinkSnap = Duration(milliseconds: 80);

  /// Standard state-color cut.
  static const Duration stateCut = Duration(milliseconds: 90);

  /// Hit / miss / smash flash duration.
  static const Duration flash = Duration(milliseconds: 160);

  /// Center pulse one cycle.
  static const Duration pulse = Duration(milliseconds: 420);

  /// Page transition.
  static const Duration page = Duration(milliseconds: 220);
}

class MarioTheme {
  const MarioTheme._();

  /// Builds a Material 3 [ThemeData] with optional high-contrast overrides
  /// (used by the accessibility controller).
  static ThemeData build({required bool highContrast}) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: MarioColors.marioRed,
      onPrimary: MarioColors.cloudWhite,
      secondary: MarioColors.marioBlue,
      onSecondary: MarioColors.cloudWhite,
      tertiary: MarioColors.coin,
      onTertiary: MarioColors.bowserBlack,
      error: MarioColors.marioRed,
      onError: MarioColors.cloudWhite,
      surface: MarioColors.cloudWhite,
      onSurface: MarioColors.bowserBlack,
      surfaceContainerHighest: const Color(0xFFEAF3FF),
      outline: highContrast ? MarioColors.bowserBlack : const Color(0xFF1A1A1A),
      outlineVariant: const Color(0xFF555555),
    );

    final textTheme = _buildTextTheme(highContrast: highContrast);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MarioColors.sky,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: MarioColors.sky,
        foregroundColor: MarioColors.bowserBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      iconTheme: IconThemeData(
        color: MarioColors.bowserBlack,
        size: highContrast ? 28 : 24,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: MarioColors.bowserBlack,
        contentTextStyle:
            TextStyle(color: MarioColors.cloudWhite, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static TextTheme _buildTextTheme({required bool highContrast}) {
    final pixel = GoogleFonts.pressStart2pTextTheme();
    final body = GoogleFonts.nunitoTextTheme();
    final outline = highContrast ? MarioColors.bowserBlack : const Color(0xFF111111);

    return TextTheme(
      // Display & headlines use pixel font for arcade vibe (sparingly).
      displayLarge: pixel.displayLarge?.copyWith(
        fontSize: 28,
        color: outline,
        height: 1.1,
      ),
      displayMedium: pixel.displayMedium?.copyWith(
        fontSize: 22,
        color: outline,
        height: 1.15,
      ),
      headlineLarge: pixel.headlineLarge?.copyWith(
        fontSize: 20,
        color: outline,
        height: 1.2,
      ),
      headlineMedium: pixel.headlineMedium?.copyWith(
        fontSize: 16,
        color: outline,
        height: 1.25,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: outline,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: outline,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 17,
        height: 1.55,
        color: outline,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: outline,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: outline,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: outline,
      ),
    );
  }
}
