import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/enums/app_enums.dart';

void main() {
  group('TransactionType database mapping', () {
    test('round-trips every stable database value', () {
      for (final type in TransactionType.values) {
        expect(
          TransactionType.fromDbString(type.toDbString()),
          type,
          reason: '${type.toDbString()} should round-trip',
        );
      }
    });

    test(
      'rejects unknown values instead of treating them as stock increases',
      () {
        expect(
          () => TransactionType.fromDbString('UNRECOGNIZED'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => TransactionType.fromDbString(null),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
