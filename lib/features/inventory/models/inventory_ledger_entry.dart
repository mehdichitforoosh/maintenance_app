import '../../../core/enums/app_enums.dart';
import 'stock_transaction.dart';

class InventoryLedgerEntry {
  final StockTransaction transaction;
  final String itemName;
  final String itemCode;
  final String unit;

  const InventoryLedgerEntry({
    required this.transaction,
    required this.itemName,
    required this.itemCode,
    required this.unit,
  });

  String get itemId => transaction.itemId;
  String get id => transaction.id;
  TransactionType get transactionType => transaction.transactionType;
  double get quantity => transaction.quantity;
  String get transactionDate => transaction.transactionDate;
  String? get notes => transaction.notes;
}
