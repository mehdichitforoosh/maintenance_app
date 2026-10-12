class FacilityTable {
  static const String tableName = 'facilities';

  static const String id = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String address = 'address';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $name TEXT NOT NULL,
      $description TEXT,
      $address TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict'))
    )
  ''';
}
