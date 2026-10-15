import 'package:intl/intl.dart';

class AppNumberFormat {
  AppNumberFormat._();

  static final NumberFormat _decimal = NumberFormat.decimalPattern('fa_IR')
    ..maximumFractionDigits = 2
    ..minimumFractionDigits = 0;

  static String decimal(num value, {int? fractionDigits}) {
    if (fractionDigits == null) return _decimal.format(value);
    final formatter = NumberFormat.decimalPattern('fa_IR')
      ..maximumFractionDigits = fractionDigits
      ..minimumFractionDigits = fractionDigits;
    return formatter.format(value);
  }
}
