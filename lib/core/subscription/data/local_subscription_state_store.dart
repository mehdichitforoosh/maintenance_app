import 'dart:convert';

import '../../storage/key_value_storage.dart';
import '../domain/subscription_state.dart';
import '../security/subscription_integrity.dart';
import 'subscription_state_store.dart';

class LocalSubscriptionStateStore implements SubscriptionStateStore {
  static const String _key = 'subscription_state_json';
  static const String _keySignature = 'subscription_state_signature';

  @override
  Future<SubscriptionState?> load() async {
    final raw = KeyValueStorage.instance.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final signature = KeyValueStorage.instance.getString(_keySignature) ?? '';
      if (signature.isNotEmpty && !SubscriptionIntegrity.verify(decoded, signature)) {
        return null;
      }
      return SubscriptionState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(SubscriptionState state) async {
    final payload = state.toJson();
    final encoded = jsonEncode(payload);
    final signature = SubscriptionIntegrity.sign(payload);

    await KeyValueStorage.instance.setString(_key, encoded);
    await KeyValueStorage.instance.setString(_keySignature, signature);
  }
}

