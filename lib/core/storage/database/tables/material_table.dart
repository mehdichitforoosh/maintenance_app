class MaterialTable {
  static const String tableName = 'materials';

  // Columns
  static const String id = 'id';
  static const String name = 'name';
  static const String unit = 'unit'; // e.g. گرم, میلی‌لیتر, عدد, کیلوگرم
  static const String averageUnitCost = 'average_unit_cost'; // Real (Tomans per unit)
  static const String currentStock = 'current_stock'; // Real
  static const String isActive = 'is_active'; // INTEGER (0 or 1)
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $name TEXT NOT NULL,
      $unit TEXT NOT NULL,
      $averageUnitCost REAL NOT NULL DEFAULT 0,
      $currentStock REAL NOT NULL DEFAULT 0,
      $isActive INTEGER NOT NULL DEFAULT 1,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT
    )
  ''';
}
