import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/storage/database/database_helper.dart';
import 'package:maintenance_app/features/backup/repositories/backup_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/facility_repository.dart';
import 'package:maintenance_app/features/inventory/repositories/inventory_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BackupRepository tests', () {
    late DatabaseHelper dbHelper;
    late FacilityRepository facilityRepo;
    late InventoryRepository inventoryRepo;
    late BackupRepository backupRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.initialize(inMemory: true);
      facilityRepo = FacilityRepository(dbHelper: dbHelper);
      inventoryRepo = InventoryRepository(dbHelper: dbHelper);
      backupRepo = BackupRepository();
    });

    test('exportBackupJson exports all 15 tables with valid header structure', () async {
      // 1. Create seed data
      final facility = await facilityRepo.createFacility(
        name: 'کارگاه نمونه پشتیبان',
        description: 'تست پشتیبان‌گیری',
      );

      final item = await inventoryRepo.createItem(
        name: 'روغن هیدرولیک 46',
        code: 'OIL-46',
        unit: 'لیتر',
      );

      // 2. Export backup JSON
      final jsonStr = await backupRepo.exportBackupJson();
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;

      expect(decoded['app'], equals('maintenance_app'));
      expect(decoded['version'], equals(1));
      expect(decoded.containsKey('exported_at'), isTrue);

      final tables = decoded['tables'] as Map<String, dynamic>;
      expect(tables.length, equals(15));
      expect(tables.containsKey('facilities'), isTrue);
      expect(tables.containsKey('inventory_items'), isTrue);

      final facilitiesList = tables['facilities'] as List<dynamic>;
      expect(facilitiesList.length, equals(1));
      expect(facilitiesList.first['id'], equals(facility.id));

      final itemsList = tables['inventory_items'] as List<dynamic>;
      expect(itemsList.length, equals(1));
      expect(itemsList.first['id'], equals(item.id));
    });

    test('importBackupJson restores data inside atomic transaction', () async {
      // 1. Create seed data and export
      final facility = await facilityRepo.createFacility(
        name: 'کارگاه اصلی',
      );
      await inventoryRepo.createItem(
        name: 'فیلتر هوا',
        code: 'FLT-01',
        unit: 'عدد',
      );

      final exportedJson = await backupRepo.exportBackupJson();

      // 2. Add extra data that should be wiped on restore
      await facilityRepo.createFacility(name: 'کارگاه موقت ۲');

      final db = await dbHelper.db;
      final beforeCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM facilities'),
      );
      expect(beforeCount, equals(2));

      // 3. Restore backup
      await backupRepo.importBackupJson(exportedJson);

      // 4. Verify restored state
      final afterCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM facilities'),
      );
      expect(afterCount, equals(1));

      final restoredFacility = await facilityRepo.getPrimaryFacility();
      expect(restoredFacility?.id, equals(facility.id));
      expect(restoredFacility?.name, equals('کارگاه اصلی'));
    });
  });
}
