import '../../storage/key_value_storage.dart';
import '../domain/access_mode.dart';
import '../domain/app_feature.dart';
import '../domain/subscription_state.dart';
import '../data/subscription_state_store.dart';
import 'subscription_policy.dart';

class AccessDeniedException implements Exception {
  final String message;
  const AccessDeniedException(this.message);

  @override
  String toString() => message;
}

abstract interface class FeatureAccessService {
  Future<AccessDecision> checkAccess({
    required AppFeature feature,
    required AccessOperation operation,
  });

  Future<void> requireAccess({
    required AppFeature feature,
    required AccessOperation operation,
  });
}

class DefaultFeatureAccessService implements FeatureAccessService {
  final SubscriptionStateStore store;
  final SubscriptionPolicy policy;
  final DateTime Function() clock;

  DefaultFeatureAccessService({
    required this.store,
    required this.policy,
    required this.clock,
  });

  @override
  Future<AccessDecision> checkAccess({
    required AppFeature feature,
    required AccessOperation operation,
  }) async {
    if (KeyValueStorage.instance.isFirstRun && operation == AccessOperation.write) {
      return const AccessDecision(
        accessMode: AccessMode.fullAccess,
        reason: 'initial_setup',
      );
    }

    final rawState = await store.load() ?? const SubscriptionState();
    final normalizedState = _normalizeState(rawState);
    final now = clock().toUtc();
    final decision = policy.evaluate(normalizedState, now);

    if (operation == AccessOperation.read) {
      return decision;
    }

    if (decision.accessMode == AccessMode.fullAccess) {
      return decision;
    }

    throw AccessDeniedException(
      _farsiMessageFor(feature, decision.reason),
    );
  }

  @override
  Future<void> requireAccess({
    required AppFeature feature,
    required AccessOperation operation,
  }) async {
    await checkAccess(feature: feature, operation: operation);
  }

  String _farsiMessageFor(AppFeature feature, String reason) {
    final featureName = switch (feature) {
      AppFeature.facility => 'کارگاه',
      AppFeature.assets => 'تجهیزات',
      AppFeature.locations => 'موقعیت‌ها',
      AppFeature.maintenancePlans => 'برنامه‌های نگهداری',
      AppFeature.workOrders => 'کارهای تعمیراتی',
      AppFeature.inventory => 'موجودی انبار',
      AppFeature.purchases => 'سفارشات خرید',
      AppFeature.alerts => 'هشدارها',
      AppFeature.reports => 'گزارش‌ها',
      AppFeature.settings => 'تنظیمات',
    };

    final reasonText = switch (reason) {
      'trial_active' => 'دوره آزمایش فعال است',
      'paid_active' => 'اشتراک فعال است',
      'trial_expired' => 'دوره آزمایش به پایان رسیده است',
      'not_started' => 'دوره آزمایش شروع نشده است',
      'initial_setup' => 'تنظیم اولیه در حال اجرا است',
      _ => 'دسترسی محدود است',
    };

    return 'دسترسی به «$featureName» رد شد: $reasonText.';
  }

  SubscriptionState _normalizeState(SubscriptionState state) {
    final now = clock().toUtc();
    final lastSeen = state.lastSeenAtUtc;

    if (lastSeen != null && now.isBefore(lastSeen.toUtc())) {
      return state.copyWith(
        trialStartedAtUtc: null,
        trialEndsAtUtc: null,
        entitlementStartedAtUtc: null,
        entitlementEndsAtUtc: null,
        lastSeenAtUtc: now,
      );
    }

    return state.copyWith(lastSeenAtUtc: now);
  }
}

