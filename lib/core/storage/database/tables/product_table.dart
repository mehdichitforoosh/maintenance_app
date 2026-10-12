import 'category_table.dart';

class ProductTable {
  static const String tableName = 'products';

  // Columns
  static const String id = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String image = 'image';
  static const String categoryId = 'category_id';
  static const String salePrice = 'sale_price';
  static const String costPrice = 'cost_price';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $name TEXT NOT NULL,
      $description TEXT,
      $image TEXT,
      $categoryId TEXT NOT NULL,
      $salePrice INTEGER NOT NULL DEFAULT 0,
      $costPrice INTEGER NOT NULL DEFAULT 0,
      $isActive INTEGER NOT NULL DEFAULT 1,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT,

      FOREIGN KEY ($categoryId)
        REFERENCES ${CategoryTable.tableName}(${CategoryTable.id})
    )
  ''';

  static const String createCategoryIndex =
      '''
    CREATE INDEX idx_products_category
    ON $tableName($categoryId)
  ''';
}
