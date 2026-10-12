import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/inventory_item.dart';
import '../models/stock_transaction.dart';
import '../repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(dbHelper: ref.watch(databaseHelperProvider));
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getItems();
});

final lowStockItemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getLowStockItems();
});

final stockTransactionsProvider = FutureProvider.family<List<StockTransaction>, String>((ref, itemId) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getStockTransactions(itemId);
});
