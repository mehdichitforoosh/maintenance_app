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
      onSurface: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.vazirmatn().fontFamily,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: Colors.white,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.lightTextTheme,
      inputDecorationTheme: AppTextTheme.lightInputDecorationTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          side: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'VazirmatnFD',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'VazirmatnFD',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
              fontFamily: 'VazirmatnFD',
            );
          }
          return TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontFamily: 'VazirmatnFD',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              size: 24,
              color: Color(0xFF1D4ED8),
            );
          }
          return IconThemeData(
            size: 22,
            color: Colors.grey.shade600,
          );
        }),
      ),
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE0E0E0),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          side: BorderSide(color: Color(0xFF334155), width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'VazirmatnFD',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'VazirmatnFD',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF1E3A8A),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'VazirmatnFD',
            );
          }
          return TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontFamily: 'VazirmatnFD',
          );
        }),
      ),
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
