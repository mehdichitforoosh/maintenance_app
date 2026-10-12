import 'sale_table.dart';
import 'product_table.dart';

class SaleItemTable {
  static const String tableName = 'sale_items';

  // Columns
  static const String id = 'id';
  static const String saleId = 'sale_id';
  static const String productId = 'product_id';
  static const String quantity = 'quantity';
  static const String unitPrice = 'unit_price';
  static const String totalAmount = 'total_amount';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $saleId TEXT NOT NULL,
      $productId TEXT NOT NULL,
      $quantity INTEGER NOT NULL,
      $unitPrice INTEGER NOT NULL,
      $totalAmount INTEGER NOT NULL,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT,
      FOREIGN KEY ($saleId) REFERENCES ${SaleTable.tableName}(${SaleTable.id}) ON DELETE CASCADE,
      FOREIGN KEY ($productId) REFERENCES ${ProductTable.tableName}(${ProductTable.id})
    )
  ''';

  static const String createSaleIndex = '''
    CREATE INDEX idx_sale_items_sale ON $tableName($saleId)
  ''';
}
