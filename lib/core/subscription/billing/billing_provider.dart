import '../domain/plan_id.dart';

abstract interface class BillingProduct {
  final String id;
  final String name;
  final String? description;

  const BillingProduct({
    required this.id,
    required this.name,
    this.description,
  });
}

abstract interface class BillingPurchaseResult {
  const BillingPurchaseResult();
}

class BillingPurchaseSuccess extends BillingPurchaseResult {
  final String purchaseId;
  const BillingPurchaseSuccess({required this.purchaseId});
}

class BillingPurchasePending extends BillingPurchaseResult {
  const BillingPurchasePending();
}

class BillingPurchaseCancelled extends BillingPurchaseResult {
  const BillingPurchaseCancelled();
}

class BillingPurchaseFailure extends BillingPurchaseResult {
  final String message;
  const BillingPurchaseFailure({required this.message});
}

abstract interface class BillingPurchaseRecord {
  final String id;
  final String productId;
  final String? providerId;
  final DateTime? purchasedAtUtc;

  const BillingPurchaseRecord({
    required this.id,
    required this.productId,
    this.providerId,
    this.purchasedAtUtc,
  });
}

abstract interface class BillingProvider {
  Future<bool> isAvailable();
  Future<List<BillingProduct>> loadProducts();
  Future<BillingPurchaseResult> purchase(SubscriptionPlanId planId);
  Future<List<BillingPurchaseRecord>> restorePurchases();
  Future<void> dispose();
}

