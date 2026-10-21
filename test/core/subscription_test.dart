import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/subscription/application/subscription_policy.dart';
import 'package:maintenance_app/core/subscription/application/subscription_service.dart';
import 'package:maintenance_app/core/subscription/data/subscription_state_store.dart';
import 'package:maintenance_app/core/subscription/domain/access_mode.dart';
import 'package:maintenance_app/core/subscription/domain/subscription_state.dart';
import 'package:maintenance_app/core/subscription/domain/subscription_status.dart';

void main() {
  group('SubscriptionService', () {
    test('starts a single 15-day trial', () async {
      final store = _MemorySubscriptionStore();
      var now = DateTime.utc(2026, 10, 21);
      final service = SubscriptionService(store: store, clock: () => now);

      final started = await service.startTrial();
      now = now.add(const Duration(days: 2));
      final repeated = await service.startTrial();

      expect(started.status, SubscriptionStatus.trialing);
      expect(started.trialStartedAtUtc, DateTime.utc(2026, 10, 21));
      expect(started.trialEndsAtUtc, DateTime.utc(2026, 11, 5));
      expect(repeated.trialStartedAtUtc, started.trialStartedAtUtc);
      expect(repeated.trialEndsAtUtc, started.trialEndsAtUtc);
    });

    test('clears entitlements when the device clock moves backwards', () async {
      final store = _MemorySubscriptionStore(
        SubscriptionState(
          planId: 'trial',
          status: SubscriptionStatus.trialing,
          trialStartedAtUtc: DateTime.utc(2026, 10, 20),
          trialEndsAtUtc: DateTime.utc(2026, 11, 4),
          entitlementStartedAtUtc: DateTime.utc(2026, 10, 20),
          entitlementEndsAtUtc: DateTime.utc(2027, 10, 20),
          lastSeenAtUtc: DateTime.utc(2026, 10, 21),
        ),
      );
      final service = SubscriptionService(
        store: store,
        clock: () => DateTime.utc(2026, 10, 19),
      );

      final state = await service.resetIfClockMovedBackwards();

      expect(state.trialStartedAtUtc, DateTime.utc(2026, 10, 20));
      expect(state.trialEndsAtUtc, isNull);
      expect(state.entitlementStartedAtUtc, isNull);
      expect(state.entitlementEndsAtUtc, isNull);
      expect(state.status, SubscriptionStatus.revoked);
      expect(await store.load(), state);

      final stillRevoked = await service.startTrial();
      expect(stillRevoked.status, SubscriptionStatus.revoked);
      expect(stillRevoked.trialEndsAtUtc, isNull);
    });
  });

  group('SubscriptionPolicy', () {
    test('grants access only while the trial is active', () {
      const policy = SubscriptionPolicy();
      final state = SubscriptionState(
        status: SubscriptionStatus.trialing,
        trialStartedAtUtc: DateTime.utc(2026, 10, 1),
        trialEndsAtUtc: DateTime.utc(2026, 10, 16),
      );

      expect(
        policy.evaluate(state, DateTime.utc(2026, 10, 15)).accessMode,
        AccessMode.fullAccess,
      );
      expect(
        policy.evaluate(state, DateTime.utc(2026, 10, 16)).accessMode,
        AccessMode.readOnly,
      );
      expect(
        policy
            .evaluate(
              SubscriptionState(
                planId: 'trial',
                status: SubscriptionStatus.revoked,
                trialStartedAtUtc: DateTime.utc(2026, 10, 1),
              ),
              DateTime.utc(2026, 10, 15),
            )
            .accessMode,
        AccessMode.readOnly,
      );
    });
  });
}

class _MemorySubscriptionStore implements SubscriptionStateStore {
  SubscriptionState? state;

  _MemorySubscriptionStore([this.state]);

  @override
  Future<SubscriptionState?> load() async => state;

  @override
  Future<void> save(SubscriptionState state) async {
    this.state = state;
  }
}
