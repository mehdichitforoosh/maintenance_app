import 'material_table.dart';
import 'product_table.dart';

class RecipeItemTable {
  static const String tableName = 'recipe_items';

  // Columns
  static const String id = 'id';
  static const String productId = 'product_id';
  static const String materialId = 'material_id';
  static const String quantity = 'quantity'; // Real quantity per product
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $productId TEXT NOT NULL,
      $materialId TEXT NOT NULL,
      $quantity REAL NOT NULL DEFAULT 0,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT,
      FOREIGN KEY ($productId) REFERENCES ${ProductTable.tableName}(${ProductTable.id}) ON DELETE CASCADE,
      FOREIGN KEY ($materialId) REFERENCES ${MaterialTable.tableName}(${MaterialTable.id})
    )
  ''';

  static const String createProductIndex = '''
    CREATE INDEX idx_recipe_items_product ON $tableName($productId)
  ''';
}
