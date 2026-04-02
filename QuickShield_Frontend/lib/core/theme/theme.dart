import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class QSTheme {
  QSTheme._();

  static ThemeData build() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: QSColors.bg,
      primaryColor: QSColors.primary,

      colorScheme: const ColorScheme.dark(
        primary: QSColors.primary,
        secondary: QSColors.accent,
        surface: QSColors.card,
        error: QSColors.red,
        onPrimary: Colors.white,
        onSurface: QSColors.textDark,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: QSColors.textOnDark,
        titleTextStyle: GoogleFonts.inter(
          color: QSColors.textOnDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),

      cardTheme: const CardThemeData(
        color: QSColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QSColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QSColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: QSColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: QSColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: QSColors.primary, width: 1.5),
        ),
        hintStyle:
            GoogleFonts.inter(color: QSColors.textMuted, fontSize: 14),
        prefixIconColor: QSColors.textLight,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: QSColors.primary,
        inactiveTrackColor: QSColors.border,
        thumbColor: Colors.white,
        overlayColor: QSColors.primary.withOpacity(0.12),
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
      ),

      dividerTheme:
          const DividerThemeData(color: QSColors.border, thickness: 1),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: QSColors.textOnDark,
          letterSpacing: -2,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: QSColors.textOnDark,
          letterSpacing: -0.8,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: QSColors.textDark,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: QSColors.textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: QSColors.textMid,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: QSColors.textLight,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: QSColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}