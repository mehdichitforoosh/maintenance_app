enum SubscriptionPlanId {
  trial,
  monthly,
  threeMonths,
  sixMonths,
  yearly;

  String get value {
    switch (this) {
      case SubscriptionPlanId.trial:
        return 'trial';
      case SubscriptionPlanId.monthly:
        return 'monthly';
      case SubscriptionPlanId.threeMonths:
        return 'threeMonths';
      case SubscriptionPlanId.sixMonths:
        return 'sixMonths';
      case SubscriptionPlanId.yearly:
        return 'yearly';
    }
  }

  static SubscriptionPlanId fromValue(String? value) {
    switch (value) {
      case 'trial':
        return SubscriptionPlanId.trial;
      case 'monthly':
        return SubscriptionPlanId.monthly;
      case 'threeMonths':
        return SubscriptionPlanId.threeMonths;
      case 'sixMonths':
        return SubscriptionPlanId.sixMonths;
      case 'yearly':
        return SubscriptionPlanId.yearly;
      default:
        return SubscriptionPlanId.trial;
    }
  }
}

