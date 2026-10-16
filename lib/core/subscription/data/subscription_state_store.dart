import '../domain/subscription_state.dart';

abstract interface class SubscriptionStateStore {
  Future<SubscriptionState?> load();
  Future<void> save(SubscriptionState state);
}

