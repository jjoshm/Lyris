import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lyris Tracker design system — elegant, warm, modern.
/// Supports light and dark mode with smooth transitions.
class LyrisTheme {
  // ─── Brand Colors ────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE8527A); // Warm rose
  static const Color primaryLight = Color(0xFFF8BBD0);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color accent = Color(0xFFAB47BC); // Soft violet

  // ─── Cycle Phase Colors ──────────────────────────────────────────────
  static const Color periodColor = Color(0xFFE8527A);
  static const Color follicularColor = Color(0xFF66BB6A);
  static const Color fertileColor = Color(0xFFAB47BC);
  static const Color ovulationColor = Color(0xFF7E57C2);
  static const Color pmsColor = Color(0xFF5C6BC0);

  // ─── Calendar phase colors (theme-adaptive) ──────────────────────────
  /// Returns fill/border colors for calendar cells that work in both themes.
  /// Dark mode uses higher opacity so colors are visible on dark surfaces.
  static double calOpacity(bool isDark, double lightVal, double darkVal) =>
      isDark ? darkVal : lightVal;

  // ─── Semantic ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  static Color phaseColor(String phase) {
    switch (phase) {
      case 'period':
        return periodColor;
      case 'follicular':
        return follicularColor;
      case 'fertile':
        return fertileColor;
      case 'ovulation':
        return ovulationColor;
      case 'pms':
        return pmsColor;
      default:
        return primary;
    }
  }

  // ─── Light Theme ─────────────────────────────────────────────────────
  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        bg: const Color(0xFFFAF8F9),
        surface: const Color(0xFFFFFFFF),
        surfaceVariant: const Color(0xFFF5F0F2),
        text: const Color(0xFF2D2D3A),
        textSecondary: const Color(0xFF8E8E9A),
        divider: const Color(0xFFF0E8EC),
      );

  // ─── Dark Theme ──────────────────────────────────────────────────────
  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        bg: const Color(0xFF1A1A2E),
        surface: const Color(0xFF252540),
        surfaceVariant: const Color(0xFF2F2F4A),
        text: const Color(0xFFF0EDF2),
        textSecondary: const Color(0xFFA0A0B8),
        divider: const Color(0xFF3A3A55),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceVariant,
    required Color text,
    required Color textSecondary,
    required Color divider,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        onSurfaceVariant: textSecondary,
        error: error,
        onError: Colors.white,
        outline: divider,
        surfaceContainerHighest: surfaceVariant,
      ),
      dividerColor: divider,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: text),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
