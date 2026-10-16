class SubscriptionState {
  final String? planId;
  final DateTime? trialStartedAtUtc;
  final DateTime? trialEndsAtUtc;
  final DateTime? entitlementStartedAtUtc;
  final DateTime? entitlementEndsAtUtc;
  final DateTime? lastSeenAtUtc;

  const SubscriptionState({
    this.planId,
    this.trialStartedAtUtc,
    this.trialEndsAtUtc,
    this.entitlementStartedAtUtc,
    this.entitlementEndsAtUtc,
    this.lastSeenAtUtc,
  });

  bool get hasTrialStarted => trialStartedAtUtc != null;

  SubscriptionState copyWith({
    String? planId,
    DateTime? trialStartedAtUtc,
    DateTime? trialEndsAtUtc,
    DateTime? entitlementStartedAtUtc,
    DateTime? entitlementEndsAtUtc,
    DateTime? lastSeenAtUtc,
  }) {
    return SubscriptionState(
      planId: planId ?? this.planId,
      trialStartedAtUtc: trialStartedAtUtc ?? this.trialStartedAtUtc,
      trialEndsAtUtc: trialEndsAtUtc ?? this.trialEndsAtUtc,
      entitlementStartedAtUtc:
          entitlementStartedAtUtc ?? this.entitlementStartedAtUtc,
      entitlementEndsAtUtc: entitlementEndsAtUtc ?? this.entitlementEndsAtUtc,
      lastSeenAtUtc: lastSeenAtUtc ?? this.lastSeenAtUtc,
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'trialStartedAtUtc': trialStartedAtUtc?.toUtc().toIso8601String(),
        'trialEndsAtUtc': trialEndsAtUtc?.toUtc().toIso8601String(),
        'entitlementStartedAtUtc':
            entitlementStartedAtUtc?.toUtc().toIso8601String(),
        'entitlementEndsAtUtc': entitlementEndsAtUtc?.toUtc().toIso8601String(),
        'lastSeenAtUtc': lastSeenAtUtc?.toUtc().toIso8601String(),
      };

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString())?.toUtc();
    }

    return SubscriptionState(
      planId: json['planId'] as String?,
      trialStartedAtUtc: parseDate(json['trialStartedAtUtc']),
      trialEndsAtUtc: parseDate(json['trialEndsAtUtc']),
      entitlementStartedAtUtc: parseDate(json['entitlementStartedAtUtc']),
      entitlementEndsAtUtc: parseDate(json['entitlementEndsAtUtc']),
      lastSeenAtUtc: parseDate(json['lastSeenAtUtc']),
    );
  }
}

