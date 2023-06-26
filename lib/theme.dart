import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData customTheme = ThemeData(
    colorScheme: const ColorScheme(
      primary: Color(0xff006780),
      secondary: Color(0xff4c626b),
      surface: Color(0xfffbfcfe),
      background: Color(0xfffbfcfe),
      error: Color(0xffba1a1a),
      onPrimary: Color(0xffffffff),
      onSecondary: Color(0xffffffff),
      onSurface: Color(0xff191c1d),
      onBackground: Color(0xff191c1d),
      onError: Color(0xffffffff),
      brightness: Brightness.light,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor:
            MaterialStateProperty.all<Color>(const Color(0xff006780)),
        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
      ),
    ),
  );
}
