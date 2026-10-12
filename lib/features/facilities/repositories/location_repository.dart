import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/location.dart';

class LocationRepository {
  final DatabaseHelper _dbHelper;

  LocationRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Location>> getLocations(String facilityId) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'locations',
      where: 'facility_id = ? AND deleted_at IS NULL',
      whereArgs: [facilityId],
      orderBy: 'name ASC',
    );
    return results.map((m) => Location.fromMap(m)).toList();
  }

  Future<Location?> getLocationById(String id) async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'locations',
      where: 'id = ? AND deleted_at IS NULL',
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
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('locations', location.toMap());
    return location;
  }

  Future<Location> updateLocation(Location location, {String? parentLocationId}) async {
    final db = await _dbHelper.db;
    if (parentLocationId != null) {
      if (parentLocationId == location.id) {
        throw ArgumentError('مکان نمی‌تواند والد خودش باشد.');
      }
      final parent = await getLocationById(parentLocationId);
      if (parent == null || parent.facilityId != location.facilityId) {
        throw ArgumentError('مکان والد نامعتبر است.');
      }
    }

    final updated = location.copyWith(
      parentLocationId: parentLocationId ?? location.parentLocationId,
      updatedAt: AppDateUtils.nowUtcIso(),
    );

    await db.update(
      'locations',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
    return updated;
  }

  Future<void> deleteLocation(String id) async {
    final db = await _dbHelper.db;
    final now = AppDateUtils.nowUtcIso();
    await db.update(
      'locations',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
