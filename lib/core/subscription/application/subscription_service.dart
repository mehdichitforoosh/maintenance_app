import '../data/subscription_state_store.dart';
import '../domain/subscription_status.dart';
import '../domain/subscription_state.dart';

class SubscriptionService {
  final SubscriptionStateStore store;
  final DateTime Function() clock;

  SubscriptionService({required this.store, required this.clock});

  Future<SubscriptionState?> load() => store.load();

  Future<SubscriptionState> startTrial() async {
    final saved = await store.load() ?? const SubscriptionState();
    if (saved.trialStartedAtUtc != null || saved.planId != null) {
      return saved;
    }

    final now = clock().toUtc();
    final end = now.add(const Duration(days: 15));

    final next = saved.copyWith(
      planId: 'trial',
      status: SubscriptionStatus.trialing,
      trialStartedAtUtc: now,
      trialEndsAtUtc: end,
      lastSeenAtUtc: now,
    );

    await store.save(next);
    return next;
  }

  Future<SubscriptionState> resetIfClockMovedBackwards() async {
    final saved = await store.load() ?? const SubscriptionState();
    final now = clock().toUtc();
    final lastSeen = saved.lastSeenAtUtc;

    if (lastSeen != null && now.isBefore(lastSeen.toUtc())) {
      final reset = saved.copyWith(
        clearTrialEndDate: true,
        clearEntitlement: true,
        status: SubscriptionStatus.revoked,
        lastSeenAtUtc: now,
      );
      await store.save(reset);
      return reset;
    }

    return saved;
  }
}
