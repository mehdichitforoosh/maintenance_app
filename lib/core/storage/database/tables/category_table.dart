class CategoryTable {
  // Table
  static const String tableName = 'categories';

  // Columns
  static const String id = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String image = 'image';
  static const String type = 'type';
  static const String isDefault = 'is_default';
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
      $type TEXT NOT NULL
        CHECK ($type IN ('product', 'expense')),
      $isDefault INTEGER NOT NULL DEFAULT 0,
      $isActive INTEGER NOT NULL DEFAULT 1,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT
    )
  ''';

  static const String createNameTypeIndex =
      '''
    CREATE UNIQUE INDEX idx_categories_name_type
    ON $tableName($name, $type)
  ''';
}
