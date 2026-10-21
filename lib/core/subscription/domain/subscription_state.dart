import 'plan_id.dart';
import 'subscription_status.dart';

class SubscriptionState {
  final String? planId;
  final SubscriptionStatus status;
  final DateTime? trialStartedAtUtc;
  final DateTime? trialEndsAtUtc;
  final DateTime? entitlementStartedAtUtc;
  final DateTime? entitlementEndsAtUtc;
  final DateTime? lastSeenAtUtc;
  final String? providerId;
  final String? storeProductId;
  final String? purchaseReference;
  final DateTime? lastVerifiedAtUtc;
  final bool renewalEnabled;

  const SubscriptionState({
    this.planId,
    this.status = SubscriptionStatus.notStarted,
    this.trialStartedAtUtc,
    this.trialEndsAtUtc,
    this.entitlementStartedAtUtc,
    this.entitlementEndsAtUtc,
    this.lastSeenAtUtc,
    this.providerId,
    this.storeProductId,
    this.purchaseReference,
    this.lastVerifiedAtUtc,
    this.renewalEnabled = false,
  });

  SubscriptionState copyWith({
    String? planId,
    SubscriptionStatus? status,
    DateTime? trialStartedAtUtc,
    DateTime? trialEndsAtUtc,
    DateTime? entitlementStartedAtUtc,
    DateTime? entitlementEndsAtUtc,
    DateTime? lastSeenAtUtc,
    String? providerId,
    String? storeProductId,
    String? purchaseReference,
    DateTime? lastVerifiedAtUtc,
    bool? renewalEnabled,
    bool clearTrialEndDate = false,
    bool clearEntitlement = false,
  }) {
    return SubscriptionState(
      planId: planId ?? this.planId,
      status: status ?? this.status,
      trialStartedAtUtc: trialStartedAtUtc ?? this.trialStartedAtUtc,
      trialEndsAtUtc: clearTrialEndDate
          ? null
          : trialEndsAtUtc ?? this.trialEndsAtUtc,
      entitlementStartedAtUtc: clearEntitlement
          ? null
          : entitlementStartedAtUtc ?? this.entitlementStartedAtUtc,
      entitlementEndsAtUtc: clearEntitlement
          ? null
          : entitlementEndsAtUtc ?? this.entitlementEndsAtUtc,
      lastSeenAtUtc: lastSeenAtUtc ?? this.lastSeenAtUtc,
      providerId: providerId ?? this.providerId,
      storeProductId: storeProductId ?? this.storeProductId,
      purchaseReference: purchaseReference ?? this.purchaseReference,
      lastVerifiedAtUtc: lastVerifiedAtUtc ?? this.lastVerifiedAtUtc,
      renewalEnabled: renewalEnabled ?? this.renewalEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'status': status.value,
    'trialStartedAtUtc': trialStartedAtUtc?.toUtc().toIso8601String(),
    'trialEndsAtUtc': trialEndsAtUtc?.toUtc().toIso8601String(),
    'entitlementStartedAtUtc': entitlementStartedAtUtc
        ?.toUtc()
        .toIso8601String(),
    'entitlementEndsAtUtc': entitlementEndsAtUtc?.toUtc().toIso8601String(),
    'lastSeenAtUtc': lastSeenAtUtc?.toUtc().toIso8601String(),
    'providerId': providerId,
    'storeProductId': storeProductId,
    'purchaseReference': purchaseReference,
    'lastVerifiedAtUtc': lastVerifiedAtUtc?.toUtc().toIso8601String(),
    'renewalEnabled': renewalEnabled,
  };

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value == null || value is! String || value.isEmpty) return null;
      return DateTime.tryParse(value)?.toUtc();
    }

    return SubscriptionState(
      planId: json['planId'] as String?,
      status: SubscriptionStatus.fromValue(
        (json['status'] as String?) ?? SubscriptionStatus.notStarted.value,
      ),
      trialStartedAtUtc: parseDate(json['trialStartedAtUtc']),
      trialEndsAtUtc: parseDate(json['trialEndsAtUtc']),
      entitlementStartedAtUtc: parseDate(json['entitlementStartedAtUtc']),
      entitlementEndsAtUtc: parseDate(json['entitlementEndsAtUtc']),
      lastSeenAtUtc: parseDate(json['lastSeenAtUtc']),
      providerId: json['providerId'] as String?,
      storeProductId: json['storeProductId'] as String?,
      purchaseReference: json['purchaseReference'] as String?,
      lastVerifiedAtUtc: parseDate(json['lastVerifiedAtUtc']),
      renewalEnabled: (json['renewalEnabled'] as bool?) ?? false,
    );
  }

  bool get hasTrialStarted => trialStartedAtUtc != null;
  bool get trialActiveAtNow =>
      trialStartedAtUtc != null &&
      trialEndsAtUtc != null &&
      DateTime.now().toUtc().isBefore(trialEndsAtUtc!.toUtc());

  bool get paidActiveAtNow =>
      entitlementStartedAtUtc != null &&
      entitlementEndsAtUtc != null &&
      DateTime.now().toUtc().isBefore(entitlementEndsAtUtc!.toUtc());

  String get summary => planId ?? SubscriptionPlanId.trial.value;
}
