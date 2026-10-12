import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/storage/database/database_helper.dart';
import 'package:maintenance_app/features/facilities/repositories/facility_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/location_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Database initialization and 14 tables verification', () async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.initialize(inMemory: true);

    // Verify tables exist
    final tables = [
      'facilities',
      'locations',
      'assets',
      'maintenance_plans',
      'asset_readings',
      'inventory_items',
      'maintenance_plan_materials',
      'work_orders',
      'work_order_tasks',
      'work_order_materials',
      'purchase_orders',
      'purchase_order_items',
      'stock_transactions',
      'alert_events',
    ];

    for (final table in tables) {
      final res = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      expect(res.isNotEmpty, true, reason: 'Table $table should exist');
    }

    // Verify foreign key check passes
    final fkCheck = await db.rawQuery('PRAGMA foreign_key_check');
    expect(fkCheck.isEmpty, true, reason: 'Foreign key check should return no violations');
  });

  test('Facility and Location repository operations', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.initialize(inMemory: true);

    final facilityRepo = FacilityRepository(dbHelper: dbHelper);
    final locationRepo = LocationRepository(dbHelper: dbHelper);

    final facility = await facilityRepo.createFacility(name: 'کارگاه مرکزی');
    expect(facility.name, 'کارگاه مرکزی');

    final location = await locationRepo.createLocation(
      facilityId: facility.id,
      name: 'سالن تولید A',
      code: 'LOC-A',
    );
    expect(location.name, 'سالن تولید A');
    expect(location.facilityId, facility.id);

    final fetchedLocations = await locationRepo.getLocations(facility.id);
    expect(fetchedLocations.length, 1);
  });
}
