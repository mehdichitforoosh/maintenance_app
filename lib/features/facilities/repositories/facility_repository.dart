import '../../../core/storage/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../models/facility.dart';

class FacilityRepository {
  final DatabaseHelper _dbHelper;

  FacilityRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Facility?> getPrimaryFacility() async {
    final db = await _dbHelper.db;
    final results = await db.query(
      'facilities',
      where: 'deleted_at IS NULL',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Facility.fromMap(results.first);
  }

  Future<bool> hasFacility() async {
    final facility = await getPrimaryFacility();
    return facility != null;
  }

  Future<Facility> createFacility({
    required String name,
    String? description,
    String? address,
  }) async {
    final db = await _dbHelper.db;
    final id = IdGenerator.generate();
    final now = AppDateUtils.nowUtcIso();
    final facility = Facility(
      id: id,
      name: name,
      description: description,
      address: address,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('facilities', facility.toMap());
    return facility;
  }

  Future<Facility> updateFacility(Facility facility) async {
    final db = await _dbHelper.db;
    final updated = facility.copyWith(
      updatedAt: AppDateUtils.nowUtcIso(),
    );
    await db.update(
      'facilities',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [facility.id],
    );
    return updated;
  }
}
