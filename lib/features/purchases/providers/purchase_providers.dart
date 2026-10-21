import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/app_feature.dart';
import '../../../core/subscription/providers/subscription_providers.dart';
import '../../alerts/providers/alert_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../repositories/purchase_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final purchaseOrdersProvider =
    FutureProvider.family<List<PurchaseOrder>, String>((ref, facilityId) async {
      final repo = ref.watch(purchaseRepositoryProvider);
      return repo.getPurchaseOrders(facilityId);
    });

final purchaseOrderItemsProvider =
    FutureProvider.family<List<PurchaseOrderItem>, String>((
      ref,
      purchaseOrderId,
    ) async {
      final repo = ref.watch(purchaseRepositoryProvider);
      return repo.getOrderItems(purchaseOrderId);
    });

final purchaseActionsProvider = Provider<PurchaseActions>((ref) {
  return PurchaseActions(ref);
});

class PurchaseActions {
  final Ref _ref;

  PurchaseActions(this._ref);

  Future<PurchaseOrder> createPurchaseOrder({
    required String facilityId,
    required String supplierName,
    required String orderDate,
    String? expectedDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    await _requireWriteAccess();
    final order = await _ref
        .read(purchaseRepositoryProvider)
        .createPurchaseOrder(
          facilityId: facilityId,
          supplierName: supplierName,
          orderDate: orderDate,
          expectedDate: expectedDate,
          notes: notes,
          items: items,
        );
    _refreshAfterWrite(facilityId: facilityId, orderId: order.id);
    return order;
  }

  Future<PurchaseOrder> updatePurchaseOrder(PurchaseOrder order) async {
    await _requireWriteAccess();
    final updated = await _ref
        .read(purchaseRepositoryProvider)
        .updatePurchaseOrder(order);
    _refreshAfterWrite(facilityId: order.facilityId, orderId: order.id);
    return updated;
  }

  Future<void> receiveItems({
    required String purchaseOrderId,
    required List<Map<String, dynamic>> receivedLines,
  }) async {
    await _requireWriteAccess();
    final repository = _ref.read(purchaseRepositoryProvider);
    final order = await repository.getPurchaseOrderById(purchaseOrderId);
    if (order == null) {
      throw StateError('سفارش خرید یافت نشد.');
    }
    final orderItems = await repository.getOrderItems(purchaseOrderId);

    // The repository owns the atomic receipt and stock-ledger transaction.
    await repository.receiveItems(
      purchaseOrderId: purchaseOrderId,
      receivedLines: receivedLines,
    );
    _refreshAfterWrite(
      facilityId: order.facilityId,
      orderId: purchaseOrderId,
      itemIds: orderItems.map((item) => item.itemId),
    );
  }

  Future<void> _requireWriteAccess() {
    return _ref
        .read(featureAccessServiceProvider)
        .requireAccess(
          feature: AppFeature.purchases,
          operation: AccessOperation.write,
        );
  }

  void _refreshAfterWrite({
    required String facilityId,
    required String orderId,
    Iterable<String> itemIds = const [],
  }) {
    _ref.invalidate(purchaseOrdersProvider(facilityId));
    _ref.invalidate(purchaseOrderItemsProvider(orderId));
    _ref.invalidate(inventoryItemsProvider);
    _ref.invalidate(allInventoryItemsProvider);
    _ref.invalidate(lowStockItemsProvider);
    for (final itemId in itemIds) {
      _ref.invalidate(inventoryItemProvider(itemId));
      _ref.invalidate(inventoryCurrentStockProvider(itemId));
      _ref.invalidate(stockTransactionsProvider(itemId));
    }
    _ref.invalidate(alertsProvider(facilityId));
    _ref.invalidate(dashboardSummaryProvider(facilityId));
    _ref.invalidate(dashboardTodayTasksProvider(facilityId));
    _ref.invalidate(dashboardWorkOrderStatusProvider(facilityId));
    _ref.invalidate(dashboardCompletedTaskTrendProvider(facilityId));
    _ref.invalidate(dashboardMaterialConsumptionTrendProvider(facilityId));
    _ref.invalidate(dashboardTopConsumedMaterialsProvider(facilityId));
  }
}
