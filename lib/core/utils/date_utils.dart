import 'package:shamsi_date/shamsi_date.dart';

class AppDateUtils {
  static String _toPersianDigits(String input) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String result = input;
    for (var i = 0; i < englishDigits.length; i++) {
      result = result.replaceAll(englishDigits[i], persianDigits[i]);
    }
    return result;
  }

  static String _toEnglishDigits(String input) {
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < persianDigits.length; i++) {
      result = result.replaceAll(persianDigits[i], '$i');
    }
    return result;
  }

  /// Returns current UTC timestamp as ISO-8601 string.
  static String nowUtcIso() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Formats a DateTime or ISO string to UTC ISO-8601 string.
  static String toUtcIso(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Formats date-only as YYYY-MM-DD.
  static String formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Converts a Jalali date selected in the UI to the canonical Gregorian
  /// YYYY-MM-DD representation used for date-only values in storage.
  static String? jalaliDateToIsoDate(String? value) {
    final jalali = parseDateOnlyAsJalali(value);
    if (jalali == null) return null;
    return formatDateOnly(jalali.toGregorian().toDateTime());
  }

  /// Parses canonical Gregorian dates, legacy Jalali dates, and ISO timestamps.
  static Jalali? parseDateOnlyAsJalali(String? value) {
    final normalized = _toEnglishDigits(value?.trim() ?? '');
    if (normalized.isEmpty) return null;

    final jalaliMatch = RegExp(
      r'^(\d{4})/(\d{1,2})/(\d{1,2})$',
    ).firstMatch(normalized);
    if (jalaliMatch != null) {
      try {
        return Jalali(
          int.parse(jalaliMatch.group(1)!),
          int.parse(jalaliMatch.group(2)!),
          int.parse(jalaliMatch.group(3)!),
        );
      } on Exception {
        return null;
      }
    }

    final gregorianMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(normalized);
    if (gregorianMatch != null) {
      final year = int.parse(gregorianMatch.group(1)!);
      final month = int.parse(gregorianMatch.group(2)!);
      final day = int.parse(gregorianMatch.group(3)!);
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return Jalali.fromDateTime(date);
    }

    final timestamp = DateTime.tryParse(normalized);
    return timestamp == null ? null : Jalali.fromDateTime(timestamp.toLocal());
  }

  /// Formats a stored date-only value as a Persian Jalali date.
  /// Legacy Jalali values remain readable while data is migrated by edits.
  static String formatDateOnlyAsJalali(String? value) {
    final jalali = parseDateOnlyAsJalali(value);
    if (jalali == null) return '-';
    return _toPersianDigits(
      '${jalali.formatter.yyyy}/${jalali.formatter.mm}/${jalali.formatter.dd}',
    );
  }

  /// Parses ISO string or returns null.
  static DateTime? parseIso(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString);
  }

  /// Formats ISO string to local human-readable date and time in Persian/Jalali style.
  static String formatDisplay(String? isoString, {bool includeTime = true}) {
    return formatJalali(isoString, includeTime: includeTime);
  }

  /// Formats ISO string to Jalali (Persian) date string with Persian digits.
  static String formatJalali(String? isoString, {bool includeTime = false}) {
    final dt = parseIso(isoString);
    if (dt == null) return '-';
    final local = dt.toLocal();
    final jDate = Jalali.fromDateTime(local);
    final f = jDate.formatter;
    if (!includeTime) {
      return _toPersianDigits('${f.yyyy}/${f.mm}/${f.dd}');
    }
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return _toPersianDigits('${f.yyyy}/${f.mm}/${f.dd} $h:$min');
  }

  /// Formats an ISO timestamp as a compact Jalali month/day label.
  static String formatJalaliShort(String? isoString) {
    final dt = parseIso(isoString);
    if (dt == null) return '-';
    final formatter = Jalali.fromDateTime(dt.toLocal()).formatter;
    return _toPersianDigits('${formatter.mm}/${formatter.dd}');
  }

  /// Calendar interval addition helper respecting month length and leap years.
  static DateTime addCalendarInterval(DateTime base, int value, String unit) {
    switch (unit) {
      case 'DAY':
        return base.add(Duration(days: value));
      case 'WEEK':
        return base.add(Duration(days: value * 7));
      case 'MONTH':
        int targetYear = base.year;
        int targetMonth = base.month + value;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear += 1;
        }
        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear -= 1;
        }
        int targetDay = base.day;
        int maxDay = _daysInMonth(targetYear, targetMonth);
        if (targetDay > maxDay) {
          targetDay = maxDay;
        }
        return DateTime(
          targetYear,
          targetMonth,
          targetDay,
          base.hour,
          base.minute,
          base.second,
        );
      case 'YEAR':
        int targetYear = base.year + value;
        int targetMonth = base.month;
        int targetDay = base.day;
        if (base.month == 2 && base.day == 29 && !_isLeapYear(targetYear)) {
          targetDay = 28;
        }
        return DateTime(
          targetYear,
          targetMonth,
          targetDay,
          base.hour,
          base.minute,
          base.second,
        );
      default:
        return base.add(Duration(days: value));
    }
  }

  static bool _isLeapYear(int year) {
    return (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
  }

  static int _daysInMonth(int year, int month) {
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) return 29;
    return days[month - 1];
  }
}
