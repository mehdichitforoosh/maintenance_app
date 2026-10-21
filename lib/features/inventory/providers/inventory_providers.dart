import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/app_feature.dart';
import '../../../core/subscription/providers/subscription_providers.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/inventory_item.dart';
import '../models/stock_transaction.dart';
import '../repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final inventoryActionsProvider = Provider<InventoryActions>((ref) {
  return InventoryActions(ref);
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getItems();
});

final inventoryItemProvider = FutureProvider.family<InventoryItem?, String>((
  ref,
  itemId,
) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getItemById(itemId);
});

final inventoryCurrentStockProvider = FutureProvider.family<double, String>((
  ref,
  itemId,
) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getCurrentStock(itemId);
});

final allInventoryItemsProvider = FutureProvider<List<InventoryItem>>((
  ref,
) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getItems(activeOnly: false);
});

final lowStockItemsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getLowStockItems();
});

final stockTransactionsProvider =
    FutureProvider.family<List<StockTransaction>, String>((ref, itemId) async {
      final repo = ref.watch(inventoryRepositoryProvider);
      return repo.getStockTransactions(itemId);
    });

class InventoryActions {
  final Ref _ref;

  InventoryActions(this._ref);

  Future<InventoryItem> createItem({
    required String name,
    required String code,
    required ItemType itemType,
    required String unit,
    String? description,
    required double minimumStock,
    double? defaultUnitCost,
    required bool isActive,
  }) async {
    await _requireWriteAccess();
    final item = await _ref
        .read(inventoryRepositoryProvider)
        .createItem(
          name: name,
          code: code,
          itemType: itemType,
          unit: unit,
          description: description,
          minimumStock: minimumStock,
          defaultUnitCost: defaultUnitCost,
          isActive: isActive,
        );
    _refreshLists();
    return item;
  }

  Future<InventoryItem> updateItem(InventoryItem item) async {
    await _requireWriteAccess();
    final updated = await _ref
        .read(inventoryRepositoryProvider)
        .updateItem(item);
    _ref.invalidate(inventoryItemProvider(item.id));
    _refreshLists();
    return updated;
  }

  Future<void> adjustStock({
    required String itemId,
    required TransactionType type,
    required double quantity,
    double? unitCost,
    String? notes,
  }) async {
    await _requireWriteAccess();
    await _ref
        .read(inventoryRepositoryProvider)
        .adjustStock(
          itemId: itemId,
          type: type,
          quantity: quantity,
          unitCost: unitCost,
          notes: notes,
        );
    _ref.invalidate(inventoryCurrentStockProvider(itemId));
    _ref.invalidate(stockTransactionsProvider(itemId));
    _refreshLists();
  }

  Future<void> _requireWriteAccess() {
    return _ref
        .read(featureAccessServiceProvider)
        .requireAccess(
          feature: AppFeature.inventory,
          operation: AccessOperation.write,
        );
  }

  void _refreshLists() {
    _ref.invalidate(inventoryItemsProvider);
    _ref.invalidate(allInventoryItemsProvider);
    _ref.invalidate(lowStockItemsProvider);
  }
}
