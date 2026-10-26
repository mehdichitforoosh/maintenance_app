import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:maintenance_app/core/storage/database/migrations/database_migrations.dart';
import 'package:maintenance_app/core/storage/database/database_helper.dart';
import 'package:maintenance_app/features/assets/repositories/asset_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/facility_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/location_repository.dart';
import 'package:maintenance_app/features/inventory/repositories/inventory_repository.dart';
import 'package:maintenance_app/features/work_orders/repositories/work_order_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Database initialization and task history schema verification',
    () async {
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
        'work_order_task_events',
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
      expect(
        fkCheck.isEmpty,
        true,
        reason: 'Foreign key check should return no violations',
      );
    },
  );

  test(
    'version 1 asset reading databases are upgraded without data loss',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE asset_readings (
              id TEXT PRIMARY KEY,
              asset_id TEXT NOT NULL,
              metric_name TEXT NOT NULL,
              value REAL NOT NULL,
              unit TEXT NOT NULL,
              recorded_at TEXT NOT NULL,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT,
              sync_status TEXT NOT NULL DEFAULT 'pending'
            )
          ''');
            await db.insert('asset_readings', {
              'id': 'legacy-reading',
              'asset_id': 'legacy-asset',
              'metric_name': 'temperature',
              'value': 70,
              'unit': '°C',
              'recorded_at': '2026-10-26T00:00:00.000Z',
              'created_at': '2026-10-26T00:00:00.000Z',
              'updated_at': '2026-10-26T00:00:00.000Z',
            });
          },
        ),
      );

      try {
        await DatabaseMigrations.onUpgrade(db, 1, 2);
        await DatabaseMigrations.onUpgrade(db, 1, 2);

        final columns = await db.rawQuery('PRAGMA table_info(asset_readings)');
        final names = columns.map((column) => column['name']).toSet();
        expect(names, contains('superseded_by_reading_id'));
        expect(names, contains('correction_reason'));
        final rows = await db.query('asset_readings');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'legacy-reading');
        expect(rows.single['superseded_by_reading_id'], isNull);
        expect(rows.single['correction_reason'], isNull);
      } finally {
        await db.close();
      }
    },
  );

  test(
    'Reopening and correcting a completed task preserves stock history',
    () async {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.initialize(inMemory: true);
      final facility = await FacilityRepository(
        dbHelper: dbHelper,
      ).createFacility(name: 'کارگاه گردش‌کار');
      final asset = await AssetRepository(dbHelper: dbHelper).createAsset(
        facilityId: facility.id,
        name: 'پمپ گردش‌کار',
        code: 'P-WORKFLOW',
      );
      final repository = WorkOrderRepository(dbHelper: dbHelper);
      final workOrder = await repository.createWorkOrder(
        facilityId: facility.id,
        title: 'تعمیر و اصلاح وظیفه',
        workOrderType: WorkOrderType.corrective,
      );
      await repository.addTaskToWorkOrder(
        workOrderId: workOrder.id,
        assetId: asset.id,
        title: 'تعویض فیلتر',
      );
      final task = (await repository.getTasksForWorkOrder(workOrder.id)).single;
      final inventory = InventoryRepository(dbHelper: dbHelper);
      final item = await inventory.createItem(
        name: 'فیلتر گردش‌کار',
        code: 'FILTER-WORKFLOW',
        unit: 'عدد',
        defaultUnitCost: 10,
      );
      await inventory.adjustStock(
        itemId: item.id,
        type: TransactionType.adjustmentIn,
        quantity: 10,
      );

      await repository.completeTask(
        taskId: task.id,
        result: TaskResult.success,
        findings: 'گزارش اولیه',
        laborMinutes: 30,
        downtimeMinutes: 10,
        consumedMaterials: [
          {'item_id': item.id, 'quantity': 4, 'unit_cost': 10},
        ],
      );
      expect(await inventory.getCurrentStock(item.id), 6);

      await repository.reopenCompletedTask(
        taskId: task.id,
        reason: 'نیاز به ادامه کار',
      );
      expect(await inventory.getCurrentStock(item.id), 6);
      expect(
        (await repository.getTasksForWorkOrder(workOrder.id)).single.status,
        TaskStatus.inProgress,
      );
      expect(
        (await repository.getWorkOrderById(workOrder.id))!.status,
        WorkOrderStatus.inProgress,
      );

      await repository.completeTask(
        taskId: task.id,
        result: TaskResult.success,
        findings: 'ادامه کار انجام شد',
        laborMinutes: 45,
        downtimeMinutes: 15,
        consumedMaterials: [
          {'item_id': item.id, 'quantity': 1, 'unit_cost': 10},
        ],
      );
      expect(await inventory.getCurrentStock(item.id), 5);

      await repository.correctCompletedTask(
        taskId: task.id,
        reason: 'اصلاح مقدار مصرف ثبت‌شده',
        result: TaskResult.issueFound,
        findings: 'مقدار واقعی مصرف کمتر بود',
        laborMinutes: 40,
        downtimeMinutes: 15,
        actualMaterials: [
          {'item_id': item.id, 'quantity': 3},
        ],
      );
      expect(await inventory.getCurrentStock(item.id), 7);
      final materials = await repository.getMaterialsForTask(task.id);
      expect(materials.single.actualQuantity, 3);

      await expectLater(
        repository.correctCompletedTask(
          taskId: task.id,
          reason: 'مقدار نامعتبر',
          result: TaskResult.success,
          findings: null,
          laborMinutes: 1,
          downtimeMinutes: 0,
          actualMaterials: [
            {'item_id': item.id, 'quantity': 50},
          ],
        ),
        throwsA(isA<StateError>()),
      );
      expect(await inventory.getCurrentStock(item.id), 7);
      expect(
        (await repository.getMaterialsForTask(task.id)).single.actualQuantity,
        3,
      );

      final events = await repository.getTaskEvents(task.id);
      expect(events.map((event) => event['event_type']), [
        'COMPLETION_CORRECTED',
        'COMPLETED',
        'REOPENED',
        'COMPLETED',
      ]);
      expect(events.length, 4);

      final movements = await db.query(
        'stock_transactions',
        where: 'item_id = ?',
        whereArgs: [item.id],
        orderBy: 'created_at ASC',
      );
      expect(movements, hasLength(4));
      expect(
        movements.map((movement) => movement['transaction_type']).toList(),
        [
          'ADJUSTMENT_IN',
          'MAINTENANCE_CONSUMPTION',
          'MAINTENANCE_CONSUMPTION',
          'RETURN',
        ],
      );
    },
  );

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

  test('Task material usage posts stock only on completion', () async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.initialize(inMemory: true);
    final facility = await FacilityRepository(
      dbHelper: dbHelper,
    ).createFacility(name: 'کارگاه تست');
    final asset = await AssetRepository(
      dbHelper: dbHelper,
    ).createAsset(facilityId: facility.id, name: 'پمپ تست', code: 'P-TEST');
    final workOrderRepository = WorkOrderRepository(dbHelper: dbHelper);
    final workOrder = await workOrderRepository.createWorkOrder(
      facilityId: facility.id,
      title: 'تعمیر پمپ',
      workOrderType: WorkOrderType.corrective,
    );
    await workOrderRepository.addTaskToWorkOrder(
      workOrderId: workOrder.id,
      assetId: asset.id,
      title: 'تعویض فیلتر',
    );
    final task = (await workOrderRepository.getTasksForWorkOrder(
      workOrder.id,
    )).single;
    final inventoryRepository = InventoryRepository(dbHelper: dbHelper);
    final item = await inventoryRepository.createItem(
      name: 'فیلتر تست',
      code: 'FILTER-TEST',
      unit: 'عدد',
      defaultUnitCost: 12,
    );
    await inventoryRepository.adjustStock(
      itemId: item.id,
      type: TransactionType.adjustmentIn,
      quantity: 5,
      unitCost: 12,
    );

    await workOrderRepository.addMaterialToTask(
      workOrderTaskId: task.id,
      itemId: item.id,
      plannedQuantity: 2,
      actualQuantity: 1,
      unitCostAtUse: 10,
      notes: 'مصرف ثبت‌شده از فرم',
    );
    expect(await inventoryRepository.getCurrentStock(item.id), 5);

    await workOrderRepository.completeTask(
      taskId: task.id,
      result: TaskResult.success,
      findings: null,
      laborMinutes: 10,
      downtimeMinutes: 0,
    );

    expect(await inventoryRepository.getCurrentStock(item.id), 4);
    final materials = await workOrderRepository.getMaterialsForTask(task.id);
    expect(materials.single.plannedQuantity, 2);
    expect(materials.single.actualQuantity, 1);
    expect(materials.single.unitCostAtUse, 10);
    final movements = await db.query(
      'stock_transactions',
      where: 'item_id = ? AND transaction_type = ?',
      whereArgs: [item.id, 'MAINTENANCE_CONSUMPTION'],
    );
    expect(movements, hasLength(1));
    expect(movements.single['quantity'], 1);
  });
}
