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
