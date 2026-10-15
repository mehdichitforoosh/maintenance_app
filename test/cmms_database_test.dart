import 'package:maintenance_app/core/enums/app_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/storage/database/database_helper.dart';
import 'package:maintenance_app/features/assets/repositories/asset_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/facility_repository.dart';
import 'package:maintenance_app/features/facilities/repositories/location_repository.dart';
import 'package:maintenance_app/features/inventory/repositories/inventory_repository.dart';
import 'package:maintenance_app/features/work_orders/repositories/work_order_repository.dart';

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
    expect(
      fkCheck.isEmpty,
      true,
      reason: 'Foreign key check should return no violations',
    );
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
