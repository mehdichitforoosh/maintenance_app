import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

String toPersianDigits(String input) {
  const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  String result = input;
  for (int i = 0; i < 10; i++) {
    result = result.replaceAll(englishDigits[i], persianDigits[i]);
  }
  return result;
}

class CustomPersianMaterialLocalizations extends PersianMaterialLocalizations {
  const CustomPersianMaterialLocalizations();

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _CustomPersianMaterialLocalizationsDelegate();

  @override
  String formatDecimal(int number) {
    return toPersianDigits(super.formatDecimal(number));
  }

  @override
  String formatYear(DateTime date) {
    return toPersianDigits(super.formatYear(date));
  }

  @override
  String formatMediumDate(DateTime date) {
    return toPersianDigits(super.formatMediumDate(date));
  }

  @override
  String formatShortMonthDay(DateTime date) {
    return toPersianDigits(super.formatShortMonthDay(date));
  }

  @override
  String formatShortDate(DateTime date) {
    return toPersianDigits(super.formatShortDate(date));
  }

  @override
  String formatMonthYear(DateTime date) {
    return toPersianDigits(super.formatMonthYear(date));
  }

  @override
  String formatFullDate(DateTime date) {
    return toPersianDigits(super.formatFullDate(date));
  }

  @override
  String formatCompactDate(DateTime date) {
    return toPersianDigits(super.formatCompactDate(date));
  }
}

class _CustomPersianMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CustomPersianMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fa' && locale.countryCode == "IR";

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const CustomPersianMaterialLocalizations();
  }

  @override
  bool shouldReload(_CustomPersianMaterialLocalizationsDelegate old) => false;
}
