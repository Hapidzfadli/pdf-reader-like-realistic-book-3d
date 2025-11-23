import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  static const Color primaryColor = Color(0xFF3B82F6); // Vibrant Blue
  static const Color secondaryColor = Color(0xFF10B981); // Emerald Green
  static const Color backgroundColor = Color(0xFF0F172A); // Deep Slate Navy
  static const Color surfaceColor = Color(0xFF1E293B); // Lighter Slate
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color onBackground = Colors.white;
  static const Color onSurface = Colors.white70;

  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onBackground,
      onBackground: onBackground,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      bodyMedium: GoogleFonts.inter(color: onSurface),
      titleLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    useMaterial3: true,
  );
}
