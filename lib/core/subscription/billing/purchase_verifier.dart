import 'billing_provider.dart';

abstract interface class PurchaseVerificationResult {
  const PurchaseVerificationResult();
}

class PurchaseVerificationSuccess extends PurchaseVerificationResult {
  final String entitlementId;
  final DateTime verifiedAtUtc;
  final DateTime? expiresAtUtc;

  const PurchaseVerificationSuccess({
    required this.entitlementId,
    required this.verifiedAtUtc,
    this.expiresAtUtc,
  });
}

class PurchaseVerificationPending extends PurchaseVerificationResult {
  const PurchaseVerificationPending();
}

class PurchaseVerificationFailure extends PurchaseVerificationResult {
  final String message;
  const PurchaseVerificationFailure({required this.message});
}

abstract interface class PurchaseVerifier {
  Future<PurchaseVerificationResult> verify(
    BillingPurchaseRecord purchase,
  );
}

