import 'package:flutter/material.dart';

class AppTheme {
  // 1. Define Brand Colors
  static const Color primaryPurple = Color(0xFF4A00E0);
  static const Color secondaryPurple = Color(0xFF8E2DE2);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;

  // 2. Define Brand Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [secondaryPurple, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 3. Define the Global Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundColor,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),

      // Customize App Bar look globally
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // Customize Card look globally
      // Customize Card look globally
      // cardTheme: CardTheme(
      //   color: cardColor,
      //   elevation: 5,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // ),

      // Customize Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),

      // Customize Text Styles
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        secondary: secondaryPurple,
      ),
    );
  }
}
