enum SubscriptionStatus {
  notStarted,
  trialing,
  active,
  pending,
  expired,
  revoked,
  unknown;

  String get value {
    switch (this) {
      case SubscriptionStatus.notStarted:
        return 'notStarted';
      case SubscriptionStatus.trialing:
        return 'trialing';
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.pending:
        return 'pending';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.revoked:
        return 'revoked';
      case SubscriptionStatus.unknown:
        return 'unknown';
    }
  }

  static SubscriptionStatus fromValue(String? value) {
    switch (value) {
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'active':
        return SubscriptionStatus.active;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'revoked':
        return SubscriptionStatus.revoked;
      case 'unknown':
        return SubscriptionStatus.unknown;
      case 'notStarted':
      default:
        return SubscriptionStatus.notStarted;
    }
  }
}

