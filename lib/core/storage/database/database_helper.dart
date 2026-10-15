import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'tables/alert_event_table.dart';
import 'tables/asset_reading_table.dart';
import 'tables/asset_table.dart';
import 'tables/facility_table.dart';
import 'tables/inventory_item_table.dart';
import 'tables/location_table.dart';
import 'tables/maintenance_plan_material_table.dart';
import 'tables/maintenance_plan_table.dart';
import 'tables/purchase_order_item_table.dart';
import 'tables/purchase_order_table.dart';
import 'tables/stock_transaction_table.dart';
import 'tables/work_order_material_table.dart';
import 'tables/work_order_table.dart';
import 'tables/work_order_task_event_table.dart';
import 'tables/work_order_task_table.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  DatabaseHelper._instance();

  static const String _databaseName = 'cmms_maintenance.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  Future<Database> get db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> initialize({bool inMemory = false}) async {
    if (!inMemory && _database != null && _database!.isOpen) {
      return _database!;
    }

    _configureDatabaseFactory();
    await _closeDatabase();

    if (inMemory) {
      _database = await _openDatabase(inMemoryDatabasePath);
    } else {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, _databaseName);
      _database = await _openDatabase(path);
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await initialize(inMemory: false);
  }

  void _configureDatabaseFactory() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<void> _closeDatabase() async {
    if (_database == null || !_database!.isOpen) {
      return;
    }

    await _database!.close();
    _database = null;
  }

  Future<Database> _openDatabase(String path) async {
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Facilities
    await db.execute(FacilityTable.createTable);

    // 2. Locations
    await db.execute(LocationTable.createTable);

    // 3. Assets
    await db.execute(AssetTable.createTable);

    // 4. Maintenance Plans
    await db.execute(MaintenancePlanTable.createTable);

    // 5. Asset Readings
    await db.execute(AssetReadingTable.createTable);

    // 6. Inventory Items
    await db.execute(InventoryItemTable.createTable);

    // 7. Maintenance Plan Materials
    await db.execute(MaintenancePlanMaterialTable.createTable);

    // 8. Work Orders
    await db.execute(WorkOrderTable.createTable);

    // 9. Work Order Tasks
    await db.execute(WorkOrderTaskTable.createTable);

    // 10. Work Order Task Events
    await db.execute(WorkOrderTaskEventTable.createTable);

    // 11. Work Order Materials
    await db.execute(WorkOrderMaterialTable.createTable);

    // 12. Purchase Orders
    await db.execute(PurchaseOrderTable.createTable);

    // 13. Purchase Order Items
    await db.execute(PurchaseOrderItemTable.createTable);

    // 14. Stock Transactions
    await db.execute(StockTransactionTable.createTable);

    // 15. Alert Events
    await db.execute(AlertEventTable.createTable);

    // Indexes
    await db.execute(LocationTable.createFacilityIndex);
    await db.execute(LocationTable.createParentIndex);

    await db.execute(AssetTable.createFacilityIndex);
    await db.execute(AssetTable.createLocationIndex);
    await db.execute(AssetTable.createParentIndex);
    await db.execute(AssetTable.createStatusIndex);

    await db.execute(MaintenancePlanTable.createAssetIndex);
    await db.execute(MaintenancePlanTable.createDueIndex);
    await db.execute(MaintenancePlanTable.createTypeIndex);

    await db.execute(AssetReadingTable.createAssetMetricTimeIndex);
    await db.execute(AssetReadingTable.createSyncIndex);

    await db.execute(InventoryItemTable.createNameIndex);
    await db.execute(InventoryItemTable.createActiveIndex);

    await db.execute(MaintenancePlanMaterialTable.createPlanIndex);
    await db.execute(MaintenancePlanMaterialTable.createItemIndex);

    await db.execute(WorkOrderTable.createFacilityStatusIndex);
    await db.execute(WorkOrderTable.createScheduledIndex);
    await db.execute(WorkOrderTable.createUpdatedIndex);

    await db.execute(WorkOrderTaskTable.createOrderIndex);
    await db.execute(WorkOrderTaskTable.createAssetIndex);
    await db.execute(WorkOrderTaskTable.createPlanIndex);
    await db.execute(WorkOrderTaskTable.createStatusIndex);
    await db.execute(WorkOrderTaskTable.createDueIndex);
    await db.execute(WorkOrderTaskTable.createUniqueOccurrenceIndex);
    await db.execute(WorkOrderTaskEventTable.createTaskIndex);

    await db.execute(WorkOrderMaterialTable.createTaskIndex);
    await db.execute(WorkOrderMaterialTable.createItemIndex);

    await db.execute(PurchaseOrderTable.createFacilityStatusIndex);
    await db.execute(PurchaseOrderTable.createOrderDateIndex);
    await db.execute(PurchaseOrderItemTable.createOrderIndex);
    await db.execute(PurchaseOrderItemTable.createItemIndex);

    await db.execute(StockTransactionTable.createItemDateIndex);
    await db.execute(StockTransactionTable.createPurchaseItemIndex);
    await db.execute(StockTransactionTable.createWorkOrderMaterialIndex);

    await db.execute(AlertEventTable.createStatusTimeIndex);
    await db.execute(AlertEventTable.createFacilityIndex);
    await db.execute(AlertEventTable.createAssetIndex);
    await db.execute(AlertEventTable.createItemIndex);
    await db.execute(AlertEventTable.createUniqueDeduplicationIndex);
  }
}
