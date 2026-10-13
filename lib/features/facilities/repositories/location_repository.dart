import '../../../core/storage/database/database_helper.dart';
import '../../../core/storage/database/tables/location_table.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/location.dart';

class LocationRepository {
  static const String _tableName = LocationTable.tableName;
  final DatabaseHelper _dbHelper;

  LocationRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Location>> getLocations(String facilityId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${LocationTable.facilityId} = ? AND ${LocationTable.deletedAt} IS NULL',
      whereArgs: [facilityId],
      orderBy: '${LocationTable.name} ASC',
    );
    return results.map((m) => Location.fromMap(m)).toList();
  }

  Future<Location?> getLocationById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      _tableName,
      where: '${LocationTable.id} = ? AND ${LocationTable.deletedAt} IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Location.fromMap(results.first);
  }

  Future<Location> createLocation({
    required String facilityId,
    String? parentLocationId,
    required String name,
    String? code,
    String? description,
    bool isActive = true,
  }) async {
    final db = await _dbHelper.db;

    if (parentLocationId != null) {
      final parent = await getLocationById(parentLocationId);
      if (parent == null || parent.facilityId != facilityId) {
        throw ArgumentError('مکان والد نامعتبر است یا به تأسیسات دیگری تعلق دارد.');
      }
    }

    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();
    final location = Location(
      id: id,
      facilityId: facilityId,
      parentLocationId: parentLocationId,
      name: name,
      code: code,
      description: description,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(_tableName, location.toMap());
    return location;
  }

  Future<Location> updateLocation(Location location, {String? parentLocationId}) async {
    final db = await _dbHelper.db;
    final targetParentId = parentLocationId ?? location.parentLocationId;

    if (targetParentId != null) {
      if (targetParentId == location.id) {
        throw ArgumentError('مکان نمی‌تواند والد خودش باشد.');
      }
      final parent = await getLocationById(targetParentId);
      if (parent == null || parent.facilityId != location.facilityId) {
        throw ArgumentError('مکان والد نامعتبر است.');
      }
    }

    final updated = location.copyWith(
      parentLocationId: targetParentId,
      updatedAt: AppDateUtils.nowUtcIso(),
    );

    await db.update(
      _tableName,
      updated.toMap(),
      where: '${LocationTable.id} = ?',
      whereArgs: [location.id],
    );
    return updated;
  }

  Future<void> deleteLocation(String id) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.update(
      _tableName,
      {LocationTable.deletedAt: now, LocationTable.updatedAt: now},
      where: '${LocationTable.id} = ?',
      whereArgs: [id],
    );
  }
}
