import '../../../core/enums/app_enums.dart';
import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/asset_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/asset.dart';

class AssetRepository {
  static const String _tableName = AssetTable.tableName;
  final DatabaseHelper _dbHelper;

  AssetRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Asset>> getAssets(
    String facilityId, {
    String? searchQuery,
    String? locationId,
    AssetStatus? status,
  }) async {
    final db = await _dbHelper.db;
    var where = '${AssetTable.facilityId} = ? AND ${AssetTable.deletedAt} IS NULL';
    var args = <dynamic>[facilityId];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where += ' AND (${AssetTable.name} LIKE ? OR ${AssetTable.code} LIKE ?)';
      args.add('%${searchQuery.trim()}%');
      args.add('%${searchQuery.trim()}%');
    }
    if (locationId != null && locationId.isNotEmpty) {
      where += ' AND ${AssetTable.locationId} = ?';
      args.add(locationId);
    }
    if (status != null) {
      where += ' AND ${AssetTable.status} = ?';
      args.add(status.toDbString());
    }

    final results = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy: '${AssetTable.name} ASC',
    );
    return results.map((m) => Asset.fromMap(m)).toList();
  }

  Future<Asset?> getAssetById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${AssetTable.id} = ? AND ${AssetTable.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Asset.fromMap(results.first);
  }

  Future<List<Asset>> getChildAssets(String parentAssetId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${AssetTable.parentAssetId} = ? AND ${AssetTable.deletedAt} IS NULL',
      whereArgs: [parentAssetId],
      orderBy: '${AssetTable.name} ASC',
    );
    return results.map((m) => Asset.fromMap(m)).toList();
  }

  Future<Asset> createAsset({
    required String facilityId,
    String? locationId,
    String? parentAssetId,
    required String name,
    required String code,
    AssetType assetType = AssetType.other,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? installationDate,
    String? commissioningDate,
    AssetStatus status = AssetStatus.active,
    String? description,
  }) async {
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();

    // Check code uniqueness within facility
    final existing = await db.query(
      _tableName,
      where: '${AssetTable.facilityId} = ? AND ${AssetTable.code} = ? AND ${AssetTable.deletedAt} IS NULL',
      whereArgs: [facilityId, code],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw ArgumentError('کد تجهیز تکراری است.');
    }

    if (parentAssetId != null) {
      final parent = await getAssetById(parentAssetId);
      if (parent == null || parent.facilityId != facilityId) {
        throw ArgumentError('تجهیز والد نامعتبر است.');
      }
      if (parentAssetId == id) {
        throw ArgumentError('تجهیز نمی‌تواند والد خودش باشد.');
      }
    }

    final now = AppDateUtils.nowUtcIso();
    final asset = Asset(
      id: id,
      facilityId: facilityId,
      locationId: locationId,
      parentAssetId: parentAssetId,
      name: name,
      code: code,
      assetType: assetType,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
      installationDate: installationDate,
      commissioningDate: commissioningDate,
      status: status,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(_tableName, asset.toMap());
    return asset;
  }

  Future<Asset> updateAsset(Asset asset) async {
    final db = await _dbHelper.db;

    // Check code uniqueness
    final existing = await db.query(
      _tableName,
      where: '${AssetTable.facilityId} = ? AND ${AssetTable.code} = ? AND ${AssetTable.id} != ? AND ${AssetTable.deletedAt} IS NULL',
      whereArgs: [asset.facilityId, asset.code, asset.id],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw ArgumentError('کد تجهیز تکراری است.');
    }

    final updated = asset.copyWith(
      updatedAt: AppDateUtils.nowUtcIso(),
    );

    await db.update(
      _tableName,
      updated.toMap(),
      where: '${AssetTable.id} = ?',
      whereArgs: [asset.id],
    );
    return updated;
  }

  Future<void> deleteAsset(String id) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.update(
      _tableName,
      {AssetTable.deletedAt: now, AssetTable.updatedAt: now},
      where: '${AssetTable.id} = ?',
      whereArgs: [id],
    );
  }
}
