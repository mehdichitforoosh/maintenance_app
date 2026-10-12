import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTextTheme {
  AppTextTheme._();

  static TextTheme _buildTextTheme({required TextTheme textTheme}) {
    return GoogleFonts.vazirmatnTextTheme(textTheme);
  }

  static TextTheme get lightTextTheme =>
      _buildTextTheme(textTheme: ThemeData.light().textTheme);

  static TextTheme get darkTextTheme =>
      _buildTextTheme(textTheme: ThemeData.dark().textTheme);

  static InputDecorationThemeData get lightInputDecorationTheme =>
      InputDecorationThemeData(
        filled: true,
        fillColor: const Color(0xFFF2F4F7),
        hintStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          color: Colors.grey[500],
        ),
        labelStyle: TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          color: Colors.grey[700],
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
        prefixIconColor: Colors.grey[600],
        suffixIconColor: Colors.grey[600],
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(16.0),
        ),
      );

  static InputDecorationThemeData get darkInputDecorationTheme =>
      InputDecorationThemeData(
        filled: true,
        fillColor: const Color(0xFF262626),
        hintStyle: const TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          color: Color(0xFF999999),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          color: Color(0xFFCCCCCC),
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'VazirmatnFD',
          fontSize: 14.0,
          color: AppColors.primaryLight,
          fontWeight: FontWeight.bold,
        ),
        prefixIconColor: const Color(0xFFB0BEC5),
        suffixIconColor: const Color(0xFFB0BEC5),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF383838)),
          borderRadius: BorderRadius.circular(16.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF383838)),
          borderRadius: BorderRadius.circular(16.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          borderRadius: BorderRadius.circular(16.0),
        ),
      );
}
