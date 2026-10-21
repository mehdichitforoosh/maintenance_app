import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/feature_access_service.dart';
import '../application/subscription_policy.dart';
import '../application/subscription_service.dart';
import '../data/local_subscription_state_store.dart';
import '../domain/access_mode.dart';
import '../domain/app_feature.dart';
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

final subscriptionAccessProvider = FutureProvider<AccessDecision>((ref) {
  return ref
      .watch(featureAccessServiceProvider)
      .checkAccess(
        feature: AppFeature.inventory,
        operation: AccessOperation.read,
      );
});

final subscriptionActionsProvider = Provider<SubscriptionActions>((ref) {
  return SubscriptionActions(ref);
});

class SubscriptionActions {
  final Ref _ref;

  SubscriptionActions(this._ref);

  Future<SubscriptionState> startTrial() async {
    final state = await _ref.read(subscriptionServiceProvider).startTrial();
    _ref.invalidate(subscriptionStateProvider);
    _ref.invalidate(subscriptionAccessProvider);
    return state;
  }
}
