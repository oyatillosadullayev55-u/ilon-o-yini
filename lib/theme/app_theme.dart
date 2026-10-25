import 'package:flutter/material.dart';

/// Neon/glass ko'rinishidagi ilova mavzusi.
class AppTheme {
  static const Color background = Color(0xFF06090F);
  static const Color primary = Color(0xFF00E5A0);
  static const Color secondary = Color(0xFF35C4FF);
  static const Color gold = Color(0xFFFFC53D);

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: Color(0xFF0C1220),
      error: Color(0xFFFF5364),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: NoSplash.splashFactory,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: gold),
        titleTextStyle: TextStyle(
          color: gold,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0C1220),
        surfaceTintColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primary.withValues(alpha: 0.35)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: primary,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.07)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : Colors.white38,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.32)
              : Colors.white12,
        ),
      ),
    );
  }
}
