import '../domain/access_mode.dart';
import '../domain/subscription_state.dart';
import '../domain/subscription_status.dart';

class AccessDecision {
  final AccessMode accessMode;
  final String reason;

  const AccessDecision({required this.accessMode, required this.reason});

  bool get canWrite => accessMode == AccessMode.fullAccess;
}

class SubscriptionPolicy {
  const SubscriptionPolicy();

  AccessDecision evaluate(SubscriptionState state, DateTime nowUtc) {
    final normalizedNow = nowUtc.toUtc();

    if (state.status == SubscriptionStatus.revoked) {
      return const AccessDecision(
        accessMode: AccessMode.readOnly,
        reason: 'revoked',
      );
    }

    final trialStarted = state.trialStartedAtUtc != null;
    final trialEnds = state.trialEndsAtUtc;
    final trialIsActive =
        trialStarted &&
        trialEnds != null &&
        normalizedNow.isBefore(trialEnds.toUtc());

    final paidStarted = state.entitlementStartedAtUtc != null;
    final paidEnds = state.entitlementEndsAtUtc;
    final paidIsActive =
        paidStarted &&
        paidEnds != null &&
        normalizedNow.isBefore(paidEnds.toUtc());

    if (trialIsActive) {
      return const AccessDecision(
        accessMode: AccessMode.fullAccess,
        reason: 'trial_active',
      );
    }

    if (paidIsActive) {
      return const AccessDecision(
        accessMode: AccessMode.fullAccess,
        reason: 'paid_active',
      );
    }

    if (trialStartsAndExpired(state, normalizedNow)) {
      return const AccessDecision(
        accessMode: AccessMode.readOnly,
        reason: 'trial_expired',
      );
    }

    return const AccessDecision(
      accessMode: AccessMode.trialNotStarted,
      reason: 'not_started',
    );
  }

  bool trialStartsAndExpired(SubscriptionState state, DateTime nowUtc) {
    if (state.planId == 'trial' &&
        state.trialStartedAtUtc != null &&
        state.trialEndsAtUtc == null) {
      return true;
    }
    return state.trialStartedAtUtc != null &&
        state.trialEndsAtUtc != null &&
        !nowUtc.isBefore(state.trialEndsAtUtc!.toUtc());
  }
}
