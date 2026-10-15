import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils.addCalendarInterval', () {
    test('clamps month intervals to the last valid day', () {
      expect(
        AppDateUtils.addCalendarInterval(
          DateTime(2024, 1, 31, 10, 30),
          1,
          'MONTH',
        ),
        DateTime(2024, 2, 29, 10, 30),
      );
      expect(
        AppDateUtils.addCalendarInterval(
          DateTime(2023, 1, 31, 10, 30),
          1,
          'MONTH',
        ),
        DateTime(2023, 2, 28, 10, 30),
      );
    });

    test('handles year intervals across leap days', () {
      expect(
        AppDateUtils.addCalendarInterval(
          DateTime(2024, 2, 29, 8, 15),
          1,
          'YEAR',
        ),
        DateTime(2025, 2, 28, 8, 15),
      );
      expect(
        AppDateUtils.addCalendarInterval(
          DateTime(2024, 2, 29, 8, 15),
          4,
          'YEAR',
        ),
        DateTime(2028, 2, 29, 8, 15),
      );
    });

    test('supports day and week intervals without losing time', () {
      final base = DateTime(2026, 10, 15, 11, 43);
      expect(
        AppDateUtils.addCalendarInterval(base, 2, 'DAY'),
        DateTime(2026, 10, 17, 11, 43),
      );
      expect(
        AppDateUtils.addCalendarInterval(base, 2, 'WEEK'),
        DateTime(2026, 10, 29, 11, 43),
      );
    });
  });

  group('AppDateUtils date parsing and display', () {
    test('returns null for missing or invalid ISO values', () {
      expect(AppDateUtils.parseIso(null), isNull);
      expect(AppDateUtils.parseIso(''), isNull);
      expect(AppDateUtils.parseIso('not-a-date'), isNull);
    });

    test(
      'formats Jalali dates with Persian digits and handles invalid input',
      () {
        expect(AppDateUtils.formatJalali('not-a-date'), '-');
        expect(AppDateUtils.formatJalali('2024-03-20T12:30:00Z'), '۱۴۰۳/۰۱/۰۱');
        expect(AppDateUtils.formatJalaliShort('2024-03-20T12:30:00Z'), '۰۱/۰۱');
        expect(
          AppDateUtils.formatJalali('2024-03-20T12:30:00Z', includeTime: true),
          matches(RegExp(r'^۱۴۰۳/۰۱/۰۱ [۰-۹]{2}:[۰-۹]{2}$')),
        );
        expect(
          AppDateUtils.formatDisplay('2024-03-20T12:30:00Z'),
          AppDateUtils.formatJalali('2024-03-20T12:30:00Z', includeTime: true),
        );
      },
    );
  });
}
