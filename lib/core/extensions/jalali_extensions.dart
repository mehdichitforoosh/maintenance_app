import 'package:persian_datetime_picker/persian_datetime_picker.dart';

extension DateTimeJalaliExtension on DateTime {
  static String _toPersianDigits(String input) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(englishDigits[i], persianDigits[i]);
    }
    return result;
  }

  /// Returns short formatted Jalali date string with Persian digits (e.g. "۱۴۰۳/۰۱/۱۵")
  String toShamsiDate() {
    final j = Jalali.fromDateTime(this);
    final f = j.formatter;
    return _toPersianDigits('${f.yyyy}/${f.mm}/${f.dd}');
  }

  /// Returns full formatted Jalali date string with Persian digits (e.g. "۴ مهر ۱۴۰۵")
  String toShamsiFullDate() {
    final j = Jalali.fromDateTime(this);
    final f = j.formatter;
    return _toPersianDigits('${f.d} ${f.mN} ${f.yyyy}');
  }
}

extension DoubleFormatting on double {
  static String _toPersianDigits(String input) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'];
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹', '/'];
    String result = input;
    for (int i = 0; i < englishDigits.length; i++) {
      result = result.replaceAll(englishDigits[i], persianDigits[i]);
    }
    return result;
  }

  /// Formats double cleanly to max 2 decimal places without trailing zeros, with optional Persian digits
  String toCleanString({int maxDecimals = 2, bool usePersianDigits = true}) {
    String str;
    if (this == toInt()) {
      str = toInt().toString();
    } else {
      str = toStringAsFixed(maxDecimals);
      while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
        if (str.endsWith('.')) {
          str = str.substring(0, str.length - 1);
          break;
        }
        str = str.substring(0, str.length - 1);
      }
    }

    if (usePersianDigits) {
      return _toPersianDigits(str);
    }
    return str;
  }
}
