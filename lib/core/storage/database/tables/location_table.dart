class LocationTable {
  static const String tableName = 'locations';

  static const String id = 'id';
  static const String facilityId = 'facility_id';
  static const String parentLocationId = 'parent_location_id';
  static const String name = 'name';
  static const String code = 'code';
  static const String description = 'description';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $facilityId TEXT NOT NULL,
      $parentLocationId TEXT,
      $name TEXT NOT NULL,
      $code TEXT,
      $description TEXT,
      $isActive INTEGER NOT NULL DEFAULT 1 CHECK ($isActive IN (0,1)),
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($facilityId) REFERENCES facilities(id),
      FOREIGN KEY ($parentLocationId) REFERENCES locations(id),
      UNIQUE ($facilityId, $code)
    )
  ''';

  static const String createFacilityIndex = 'CREATE INDEX idx_locations_facility ON $tableName($facilityId)';
  static const String createParentIndex = 'CREATE INDEX idx_locations_parent ON $tableName($parentLocationId)';
}
