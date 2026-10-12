import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'app_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.vazirmatn().fontFamily,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: Colors.white,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.lightTextTheme,
      inputDecorationTheme: AppTextTheme.lightInputDecorationTheme,
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.white,
        elevation: 8,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        yearStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 16.0,
        ),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
        hourMinuteTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 48.0,
          fontWeight: FontWeight.bold,
        ),
        dayPeriodTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
        dialTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
        helpTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFE0E0E0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.vazirmatn().fontFamily,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: colorScheme,
      textTheme: AppTextTheme.darkTextTheme,
      inputDecorationTheme: AppTextTheme.darkInputDecorationTheme,
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 8,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        yearStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 16.0,
        ),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        hourMinuteTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 48.0,
          fontWeight: FontWeight.bold,
        ),
        dayPeriodTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
        dialTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
        helpTextStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2,
      ),
    );
  }
}
