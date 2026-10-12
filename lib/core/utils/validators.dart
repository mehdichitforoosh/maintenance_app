class AppValidators {
  static String? required(String? value, {String fieldName = 'این فیلد'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName نمی‌تواند خالی باشد';
    }
    return null;
  }

  static String? code(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'کد نمی‌تواند خالی باشد';
    }
    final trimmed = value.trim();
    if (trimmed.contains(' ')) {
      return 'کد نباید شامل فاصله (Space) باشد';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'مقدار'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName نمی‌تواند خالی باشد';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'لطفاً یک عدد معتبر وارد کنید';
    }
    if (number <= 0) {
      return '$fieldName باید بزرگتر از صفر باشد';
    }
    return null;
  }

  static String? nonNegativeNumber(String? value, {String fieldName = 'مقدار'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName نمی‌تواند خالی باشد';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'لطفاً یک عدد معتبر وارد کنید';
    }
    if (number < 0) {
      return '$fieldName نباید منفی باشد';
    }
    return null;
  }
}
