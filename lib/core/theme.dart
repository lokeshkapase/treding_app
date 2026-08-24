import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color gainGreen = Color(0xFF16A34A);
  static const Color lossRed = Color(0xFFDC2626);
  static const Color gainFlash = Color(0x3316A34A);
  static const Color lossFlash = Color(0x33DC2626);

  static ThemeData light() {
    const seed = Color(0xFF1E3A5F);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
