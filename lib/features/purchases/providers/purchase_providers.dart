import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../repositories/purchase_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final purchaseOrdersProvider = FutureProvider.family<List<PurchaseOrder>, String>((ref, facilityId) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.getPurchaseOrders(facilityId);
});

final purchaseOrderItemsProvider = FutureProvider.family<List<PurchaseOrderItem>, String>((ref, purchaseOrderId) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.getOrderItems(purchaseOrderId);
});
