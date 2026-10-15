import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/utils/number_format_utils.dart';

void main() {
  group('AppNumberFormat.decimal', () {
    test('formats integers and decimal values with Persian digits', () {
      expect(AppNumberFormat.decimal(1234), '۱٬۲۳۴');
      expect(AppNumberFormat.decimal(12.5), '۱۲٫۵');
      expect(AppNumberFormat.decimal(12.5, fractionDigits: 2), '۱۲٫۵۰');
    });
  });
}
