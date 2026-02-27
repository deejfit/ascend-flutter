import 'package:flutter/material.dart';

/// Ascend app theme: minimal, calm dark UI, big typography for KPIs.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF0D0D0D),
        onSurface: const Color(0xFFE5E5E5),
        primary: const Color(0xFF6B8CBF),
        onPrimary: const Color(0xFF0D0D0D),
        surfaceContainerHighest: const Color(0xFF1A1A1A),
        outline: const Color(0xFF2A2A2A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      textTheme: _textTheme,
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF2A2A2A);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE5E5E5);
            }
            return const Color(0xFF888888);
          }),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static TextTheme get _textTheme {
    const onSurface = Color(0xFFE5E5E5);
    return TextTheme(
      // Big KPI numbers
      displayLarge: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        color: onSurface,
        letterSpacing: -1,
      ),
      displayMedium: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w300,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      headlineSmall: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade300,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade400,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
    );
  }
}
