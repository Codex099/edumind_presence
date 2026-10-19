import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EdumindTheme {
  // Brand Colors (Deep Navy & Royal Blue Aesthetic from EDUMIND-SCOLAIRE)
  static const Color bgDark         = Color(0xFF0A1124);
  static const Color cardDark       = Color(0xFF111D38);
  static const Color cardHoverDark  = Color(0xFF152445);
  static const Color cardSubtleDark = Color(0xFF0D172E);
  static const Color inputDark      = Color(0xFF162447);
  static const Color borderDark     = Color(0x1FFFFFFF); // 12% white

  static const Color bgLight        = Color(0xFFF4F6FB);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color borderLight    = Color(0xFFE2E8F0);

  // Accents
  static const Color primaryBlue     = Color(0xFF2563EB); // Royal Blue EDUMIND
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color accentCyan      = Color(0xFF06B6D4);

  // Status Colors (Strictly matching attendance user stories)
  static const Color presentGreen    = Color(0xFF10B981); // حاضر
  static const Color absentRed       = Color(0xFFEF4444); // غائب
  static const Color lateOrange      = Color(0xFFF59E0B); // متأخر
  static const Color excusedPurple   = Color(0xFF8B5CF6);

  // Status Backgrounds (Tinted)
  static const Color presentBgDark   = Color(0x2810B981);
  static const Color absentBgDark    = Color(0x28EF4444);
  static const Color lateBgDark      = Color(0x28F59E0B);

  static ThemeData darkTheme(String lang) {
    final isAr = lang == 'ar';
    final textTheme = isAr 
        ? GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryBlue,
      cardColor: cardDark,
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFFF1F5F9),
        displayColor: Colors.white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentCyan,
        surface: cardDark,
        error: absentRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: isAr 
            ? GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
            : GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: isAr
              ? GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)
              : GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
    );
  }

  static ThemeData lightTheme(String lang) {
    final isAr = lang == 'ar';
    final textTheme = isAr 
        ? GoogleFonts.cairoTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primaryBlue,
      cardColor: cardLight,
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFF1E293B),
        displayColor: const Color(0xFF0F172A),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentCyan,
        surface: cardLight,
        error: absentRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: isAr 
            ? GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))
            : GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: isAr
              ? GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)
              : GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
