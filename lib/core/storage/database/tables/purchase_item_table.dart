import 'material_table.dart';
import 'purchase_table.dart';

class PurchaseItemTable {
  static const String tableName = 'purchase_items';

  // Columns
  static const String id = 'id';
  static const String purchaseId = 'purchase_id';
  static const String materialId = 'material_id';
  static const String name = 'name';
  static const String quantity = 'quantity';
  static const String unitPrice = 'unit_price';
  static const String totalAmount = 'total_amount';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $purchaseId TEXT NOT NULL,
      $materialId TEXT,
      $name TEXT NOT NULL,
      $quantity REAL NOT NULL,
      $unitPrice INTEGER NOT NULL,
      $totalAmount INTEGER NOT NULL,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT,
      FOREIGN KEY ($purchaseId) REFERENCES ${PurchaseTable.tableName}(${PurchaseTable.id}) ON DELETE CASCADE,
      FOREIGN KEY ($materialId) REFERENCES ${MaterialTable.tableName}(${MaterialTable.id})
    )
  ''';

  static const String createPurchaseIndex = '''
    CREATE INDEX idx_purchase_items_purchase ON $tableName($purchaseId)
  ''';
}
