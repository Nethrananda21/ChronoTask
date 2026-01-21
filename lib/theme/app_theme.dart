import 'package:flutter/material.dart';

/// AMOLED-optimized theme for minimal battery consumption.
/// Uses pure black backgrounds and system fonts (no network calls).
class AppTheme {
  // Time-based greeting
  static String get greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // AMOLED color palette - pure black saves battery on OLED screens
  static const Color primaryDark = Color(0xFF000000);
  static const Color surfaceCard = Color(0xFF111111);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentBlue = Color(0xFF60A5FA);
  
  // Changed accentPink to Red/Orange for overdue as requested
  static const Color accentPink = Color(0xFFFF5252); // Vibrant Red-Orange
  
  static const Color accentGreen = Color(0xFF34D399);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF6B7280);

  // Simple gradient (nearly flat for performance)
  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryDark, primaryDark],
      );

  // Minimal card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
      );

  // Theme data - uses system fonts to avoid network calls
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: primaryDark,
        fontFamily: null, // Use system default font
        colorScheme: const ColorScheme.dark(
          primary: accentPurple,
          secondary: accentBlue,
          surface: surfaceCard,
          error: accentPink,
        ),
        // Minimal page transitions to save battery
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(
              allowEnterRouteSnapshotting: false,
            ),
          },
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentPurple,
            foregroundColor: textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentPurple,
          foregroundColor: textPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
