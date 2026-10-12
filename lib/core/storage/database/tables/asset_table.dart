class AssetTable {
  static const String tableName = 'assets';

  static const String id = 'id';
  static const String facilityId = 'facility_id';
  static const String locationId = 'location_id';
  static const String parentAssetId = 'parent_asset_id';
  static const String name = 'name';
  static const String code = 'code';
  static const String assetType = 'asset_type';
  static const String manufacturer = 'manufacturer';
  static const String model = 'model';
  static const String serialNumber = 'serial_number';
  static const String installationDate = 'installation_date';
  static const String commissioningDate = 'commissioning_date';
  static const String status = 'status';
  static const String description = 'description';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String syncStatus = 'sync_status';

  static const String createTable = '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $facilityId TEXT NOT NULL,
      $locationId TEXT,
      $parentAssetId TEXT,
      $name TEXT NOT NULL,
      $code TEXT NOT NULL,
      $assetType TEXT NOT NULL DEFAULT 'OTHER'
        CHECK ($assetType IN ('MACHINE','MOTOR','PUMP','COMPRESSOR','ELECTRICAL','OTHER')),
      $manufacturer TEXT,
      $model TEXT,
      $serialNumber TEXT,
      $installationDate TEXT,
      $commissioningDate TEXT,
      $status TEXT NOT NULL DEFAULT 'ACTIVE'
        CHECK ($status IN ('ACTIVE','INACTIVE','UNDER_MAINTENANCE','RETIRED')),
      $description TEXT,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $deletedAt TEXT,
      $syncStatus TEXT NOT NULL DEFAULT 'pending'
        CHECK ($syncStatus IN ('pending','synced','conflict')),
      FOREIGN KEY ($facilityId) REFERENCES facilities(id),
      FOREIGN KEY ($locationId) REFERENCES locations(id),
      FOREIGN KEY ($parentAssetId) REFERENCES assets(id),
      UNIQUE ($facilityId, $code)
    )
  ''';

  static const String createFacilityIndex = 'CREATE INDEX idx_assets_facility ON $tableName($facilityId)';
  static const String createLocationIndex = 'CREATE INDEX idx_assets_location ON $tableName($locationId)';
  static const String createParentIndex = 'CREATE INDEX idx_assets_parent ON $tableName($parentAssetId)';
  static const String createStatusIndex = 'CREATE INDEX idx_assets_status ON $tableName($status)';
}
