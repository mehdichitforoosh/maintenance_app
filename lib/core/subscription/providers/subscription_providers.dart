import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/feature_access_service.dart';
import '../application/subscription_policy.dart';
import '../application/subscription_service.dart';
import '../data/local_subscription_state_store.dart';
import '../domain/subscription_state.dart';

final subscriptionStateStoreProvider = Provider<LocalSubscriptionStateStore>(
  (ref) => LocalSubscriptionStateStore(),
);

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(
    store: ref.watch(subscriptionStateStoreProvider),
    clock: () => DateTime.now().toUtc(),
  );
});

final featureAccessServiceProvider = Provider<FeatureAccessService>((ref) {
  return DefaultFeatureAccessService(
    store: ref.watch(subscriptionStateStoreProvider),
    policy: const SubscriptionPolicy(),
    clock: () => DateTime.now().toUtc(),
  );
});

final subscriptionStateProvider = FutureProvider<SubscriptionState?>((ref) {
  return ref.watch(subscriptionStateStoreProvider).load();
});

