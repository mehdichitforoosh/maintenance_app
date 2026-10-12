class BusinessTable {
  static const String tableName = 'business';

  // Columns
  static const String id = 'id';
  static const String name = 'name';
  static const String phone = 'phone';
  static const String address = 'address';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // SQL
  static const String createTable =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $name TEXT NOT NULL,
      $phone TEXT,
      $address TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT
    )
  ''';
}
