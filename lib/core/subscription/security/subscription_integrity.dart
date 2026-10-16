import 'dart:convert';

class SubscriptionIntegrity {
  static const String _secret = 'maintenance_app_subscription_guard_v1';

  static String sign(Map<String, dynamic> payload) {
    final json = const JsonEncoder().convert(payload);
    return _hash(json);
  }

  static bool verify(Map<String, dynamic> payload, String signature) {
    return sign(payload) == signature;
  }

  static String _hash(String value) {
    final bytes = utf8.encode(value + _secret);
    final digest = bytes.fold<int>(0, (sum, b) => sum + b);
    return digest.toRadixString(16);
  }
}

