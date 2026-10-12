import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
      var databasePath = await getDatabasesPath();
      var path = join(databasePath, _databaseName);
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
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Additive migrations for future versions
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. facilities
    await db.execute('''
      CREATE TABLE facilities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict'))
      )
    ''');

    // 2. locations
    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        parent_location_id TEXT,
        name TEXT NOT NULL,
        code TEXT,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (facility_id) REFERENCES facilities(id),
        FOREIGN KEY (parent_location_id) REFERENCES locations(id),
        UNIQUE (facility_id, code)
      )
    ''');

    // 3. assets
    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        location_id TEXT,
        parent_asset_id TEXT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        asset_type TEXT NOT NULL DEFAULT 'OTHER'
          CHECK (asset_type IN ('MACHINE','MOTOR','PUMP','COMPRESSOR','ELECTRICAL','OTHER')),
        manufacturer TEXT,
        model TEXT,
        serial_number TEXT,
        installation_date TEXT,
        commissioning_date TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE'
          CHECK (status IN ('ACTIVE','INACTIVE','UNDER_MAINTENANCE','RETIRED')),
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (facility_id) REFERENCES facilities(id),
        FOREIGN KEY (location_id) REFERENCES locations(id),
        FOREIGN KEY (parent_asset_id) REFERENCES assets(id),
        UNIQUE (facility_id, code)
      )
    ''');

    // 4. maintenance_plans
    await db.execute('''
      CREATE TABLE maintenance_plans (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        activity_type TEXT NOT NULL DEFAULT 'INSPECTION'
          CHECK (activity_type IN ('INSPECTION','LUBRICATION','REPLACEMENT','CLEANING','CALIBRATION','TESTING','REPAIR','OTHER')),
        priority TEXT NOT NULL DEFAULT 'MEDIUM'
          CHECK (priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
        schedule_type TEXT NOT NULL
          CHECK (schedule_type IN ('CALENDAR','METER','CONDITION','ONE_TIME','MANUAL')),
        calendar_interval_value INTEGER,
        calendar_interval_unit TEXT
          CHECK (calendar_interval_unit IS NULL OR calendar_interval_unit IN ('DAY','WEEK','MONTH','YEAR')),
        meter_name TEXT,
        meter_interval REAL,
        meter_unit TEXT,
        last_completed_meter_value REAL,
        next_due_meter_value REAL,
        condition_config_json TEXT,
        one_time_due_at TEXT,
        start_date TEXT,
        next_due_at TEXT,
        last_completed_at TEXT,
        schedule_anchor TEXT NOT NULL DEFAULT 'COMPLETION_DATE'
          CHECK (schedule_anchor IN ('COMPLETION_DATE','PREVIOUS_DUE_DATE')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (asset_id) REFERENCES assets(id),
        CHECK (schedule_type != 'CALENDAR' OR (calendar_interval_value IS NOT NULL AND calendar_interval_value > 0 AND calendar_interval_unit IS NOT NULL)),
        CHECK (schedule_type != 'METER' OR (meter_name IS NOT NULL AND meter_interval IS NOT NULL AND meter_interval > 0 AND meter_unit IS NOT NULL)),
        CHECK (schedule_type != 'CONDITION' OR condition_config_json IS NOT NULL),
        CHECK (schedule_type != 'ONE_TIME' OR one_time_due_at IS NOT NULL)
      )
    ''');

    // 5. asset_readings
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
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (asset_id) REFERENCES assets(id)
      )
    ''');

    // 6. inventory_items
    await db.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        item_type TEXT NOT NULL DEFAULT 'CONSUMABLE'
          CHECK (item_type IN ('CONSUMABLE','SPARE_PART')),
        unit TEXT NOT NULL,
        description TEXT,
        minimum_stock REAL NOT NULL DEFAULT 0 CHECK (minimum_stock >= 0),
        default_unit_cost REAL CHECK (default_unit_cost IS NULL OR default_unit_cost >= 0),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict'))
      )
    ''');

    // 7. maintenance_plan_materials
    await db.execute('''
      CREATE TABLE maintenance_plan_materials (
        id TEXT PRIMARY KEY,
        maintenance_plan_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        planned_quantity REAL NOT NULL CHECK (planned_quantity > 0),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (maintenance_plan_id) REFERENCES maintenance_plans(id),
        FOREIGN KEY (item_id) REFERENCES inventory_items(id),
        UNIQUE (maintenance_plan_id, item_id)
      )
    ''');

    // 8. work_orders
    await db.execute('''
      CREATE TABLE work_orders (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        work_order_number TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        work_order_type TEXT NOT NULL
          CHECK (work_order_type IN ('PREVENTIVE','CORRECTIVE','EMERGENCY')),
        priority TEXT NOT NULL DEFAULT 'MEDIUM'
          CHECK (priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
        status TEXT NOT NULL DEFAULT 'OPEN'
          CHECK (status IN ('DRAFT','OPEN','IN_PROGRESS','ON_HOLD','COMPLETED','CANCELLED')),
        scheduled_at TEXT,
        started_at TEXT,
        completed_at TEXT,
        closed_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (facility_id) REFERENCES facilities(id),
        UNIQUE (facility_id, work_order_number)
      )
    ''');

    // 9. work_order_tasks
    await db.execute('''
      CREATE TABLE work_order_tasks (
        id TEXT PRIMARY KEY,
        work_order_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        maintenance_plan_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        activity_type TEXT NOT NULL DEFAULT 'INSPECTION'
          CHECK (activity_type IN ('INSPECTION','LUBRICATION','REPLACEMENT','CLEANING','CALIBRATION','TESTING','REPAIR','OTHER')),
        status TEXT NOT NULL DEFAULT 'PENDING'
          CHECK (status IN ('PENDING','IN_PROGRESS','COMPLETED','SKIPPED','CANCELLED')),
        result TEXT CHECK (result IS NULL OR result IN ('SUCCESS','ISSUE_FOUND','FAILED','FOLLOW_UP_REQUIRED')),
        scheduled_at TEXT,
        planned_due_at TEXT,
        planned_meter_value REAL,
        completion_meter_value REAL,
        completion_meter_name TEXT,
        completion_meter_unit TEXT,
        triggering_reading_id TEXT,
        source_occurrence_key TEXT,
        started_at TEXT,
        completed_at TEXT,
        findings TEXT,
        failure_description TEXT,
        follow_up_required INTEGER NOT NULL DEFAULT 0 CHECK (follow_up_required IN (0,1)),
        labor_minutes INTEGER CHECK (labor_minutes IS NULL OR labor_minutes >= 0),
        downtime_minutes INTEGER CHECK (downtime_minutes IS NULL OR downtime_minutes >= 0),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (work_order_id) REFERENCES work_orders(id),
        FOREIGN KEY (asset_id) REFERENCES assets(id),
        FOREIGN KEY (maintenance_plan_id) REFERENCES maintenance_plans(id),
        FOREIGN KEY (triggering_reading_id) REFERENCES asset_readings(id)
      )
    ''');

    // 10. work_order_materials
    await db.execute('''
      CREATE TABLE work_order_materials (
        id TEXT PRIMARY KEY,
        work_order_task_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        planned_quantity REAL CHECK (planned_quantity IS NULL OR planned_quantity >= 0),
        actual_quantity REAL CHECK (actual_quantity IS NULL OR actual_quantity >= 0),
        unit_cost_at_use REAL CHECK (unit_cost_at_use IS NULL OR unit_cost_at_use >= 0),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (work_order_task_id) REFERENCES work_order_tasks(id),
        FOREIGN KEY (item_id) REFERENCES inventory_items(id),
        UNIQUE (work_order_task_id, item_id)
      )
    ''');

    // 11. purchase_orders
    await db.execute('''
      CREATE TABLE purchase_orders (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        purchase_order_number TEXT NOT NULL,
        supplier_name TEXT,
        order_date TEXT NOT NULL,
        expected_date TEXT,
        status TEXT NOT NULL DEFAULT 'DRAFT'
          CHECK (status IN ('DRAFT','ORDERED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (facility_id) REFERENCES facilities(id),
        UNIQUE (facility_id, purchase_order_number)
      )
    ''');

    // 12. purchase_order_items
    await db.execute('''
      CREATE TABLE purchase_order_items (
        id TEXT PRIMARY KEY,
        purchase_order_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        ordered_quantity REAL NOT NULL CHECK (ordered_quantity > 0),
        unit_price REAL NOT NULL CHECK (unit_price >= 0),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
        FOREIGN KEY (item_id) REFERENCES inventory_items(id),
        UNIQUE (purchase_order_id, item_id)
      )
    ''');

    // 13. stock_transactions
    await db.execute('''
      CREATE TABLE stock_transactions (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        transaction_type TEXT NOT NULL
          CHECK (transaction_type IN ('PURCHASE_RECEIPT','MAINTENANCE_CONSUMPTION','ADJUSTMENT_IN','ADJUSTMENT_OUT','RETURN')),
        quantity REAL NOT NULL CHECK (quantity > 0),
        unit_cost REAL CHECK (unit_cost IS NULL OR unit_cost >= 0),
        transaction_date TEXT NOT NULL,
        purchase_order_item_id TEXT,
        work_order_material_id TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (item_id) REFERENCES inventory_items(id),
        FOREIGN KEY (purchase_order_item_id) REFERENCES purchase_order_items(id),
        FOREIGN KEY (work_order_material_id) REFERENCES work_order_materials(id),
        CHECK (
          (transaction_type = 'PURCHASE_RECEIPT' AND purchase_order_item_id IS NOT NULL AND work_order_material_id IS NULL)
          OR
          (transaction_type IN ('MAINTENANCE_CONSUMPTION','RETURN') AND work_order_material_id IS NOT NULL AND purchase_order_item_id IS NULL)
          OR
          (transaction_type IN ('ADJUSTMENT_IN','ADJUSTMENT_OUT') AND purchase_order_item_id IS NULL AND work_order_material_id IS NULL)
        )
      )
    ''');

    // 14. alert_events
    await db.execute('''
      CREATE TABLE alert_events (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        alert_type TEXT NOT NULL
          CHECK (alert_type IN ('MAINTENANCE_DUE','MAINTENANCE_OVERDUE','CONDITION_TRIGGERED','LOW_STOCK','WORK_ORDER_OVERDUE')),
        severity TEXT NOT NULL DEFAULT 'WARNING'
          CHECK (severity IN ('INFO','WARNING','CRITICAL')),
        status TEXT NOT NULL DEFAULT 'ACTIVE'
          CHECK (status IN ('ACTIVE','ACKNOWLEDGED','RESOLVED','DISMISSED')),
        title TEXT NOT NULL,
        message TEXT,
        asset_id TEXT,
        maintenance_plan_id TEXT,
        work_order_task_id TEXT,
        inventory_item_id TEXT,
        deduplication_key TEXT NOT NULL,
        triggered_at TEXT NOT NULL,
        acknowledged_at TEXT,
        resolved_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending','synced','conflict')),
        FOREIGN KEY (facility_id) REFERENCES facilities(id),
        FOREIGN KEY (asset_id) REFERENCES assets(id),
        FOREIGN KEY (maintenance_plan_id) REFERENCES maintenance_plans(id),
        FOREIGN KEY (work_order_task_id) REFERENCES work_order_tasks(id),
        FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(id)
      )
    ''');

    // Create Indexes
    await db.execute('CREATE INDEX idx_locations_facility ON locations(facility_id)');
    await db.execute('CREATE INDEX idx_locations_parent ON locations(parent_location_id)');

    await db.execute('CREATE INDEX idx_assets_facility ON assets(facility_id)');
    await db.execute('CREATE INDEX idx_assets_location ON assets(location_id)');
    await db.execute('CREATE INDEX idx_assets_parent ON assets(parent_asset_id)');
    await db.execute('CREATE INDEX idx_assets_status ON assets(status)');

    await db.execute('CREATE INDEX idx_maintenance_plans_asset ON maintenance_plans(asset_id)');
    await db.execute('CREATE INDEX idx_maintenance_plans_due ON maintenance_plans(next_due_at) WHERE is_active = 1 AND deleted_at IS NULL');
    await db.execute('CREATE INDEX idx_maintenance_plans_type ON maintenance_plans(schedule_type)');

    await db.execute('CREATE INDEX idx_asset_readings_asset_metric_time ON asset_readings(asset_id, metric_name, recorded_at)');
    await db.execute('CREATE INDEX idx_asset_readings_sync ON asset_readings(sync_status) WHERE deleted_at IS NULL');

    await db.execute('CREATE INDEX idx_inventory_items_name ON inventory_items(name)');
    await db.execute('CREATE INDEX idx_inventory_items_active ON inventory_items(is_active)');

    await db.execute('CREATE INDEX idx_plan_materials_plan ON maintenance_plan_materials(maintenance_plan_id)');
    await db.execute('CREATE INDEX idx_plan_materials_item ON maintenance_plan_materials(item_id)');

    await db.execute('CREATE INDEX idx_work_orders_facility_status ON work_orders(facility_id, status)');
    await db.execute('CREATE INDEX idx_work_orders_scheduled ON work_orders(scheduled_at)');
    await db.execute('CREATE INDEX idx_work_orders_updated ON work_orders(updated_at)');

    await db.execute('CREATE INDEX idx_work_order_tasks_order ON work_order_tasks(work_order_id)');
    await db.execute('CREATE INDEX idx_work_order_tasks_asset ON work_order_tasks(asset_id)');
    await db.execute('CREATE INDEX idx_work_order_tasks_plan ON work_order_tasks(maintenance_plan_id)');
    await db.execute('CREATE INDEX idx_work_order_tasks_status ON work_order_tasks(status)');
    await db.execute('CREATE INDEX idx_work_order_tasks_due ON work_order_tasks(planned_due_at)');
    await db.execute('CREATE UNIQUE INDEX uq_work_order_task_occurrence ON work_order_tasks(maintenance_plan_id, source_occurrence_key) WHERE maintenance_plan_id IS NOT NULL AND source_occurrence_key IS NOT NULL AND deleted_at IS NULL');

    await db.execute('CREATE INDEX idx_work_order_materials_task ON work_order_materials(work_order_task_id)');
    await db.execute('CREATE INDEX idx_work_order_materials_item ON work_order_materials(item_id)');

    await db.execute('CREATE INDEX idx_purchase_orders_facility_status ON purchase_orders(facility_id, status)');
    await db.execute('CREATE INDEX idx_purchase_orders_order_date ON purchase_orders(order_date)');
    await db.execute('CREATE INDEX idx_purchase_order_items_order ON purchase_order_items(purchase_order_id)');
    await db.execute('CREATE INDEX idx_purchase_order_items_item ON purchase_order_items(item_id)');

    await db.execute('CREATE INDEX idx_stock_transactions_item_date ON stock_transactions(item_id, transaction_date)');
    await db.execute('CREATE INDEX idx_stock_transactions_purchase_item ON stock_transactions(purchase_order_item_id)');
    await db.execute('CREATE INDEX idx_stock_transactions_work_order_material ON stock_transactions(work_order_material_id)');

    await db.execute('CREATE INDEX idx_alert_events_status_time ON alert_events(status, triggered_at)');
    await db.execute('CREATE INDEX idx_alert_events_facility ON alert_events(facility_id, status)');
    await db.execute('CREATE INDEX idx_alert_events_asset ON alert_events(asset_id)');
    await db.execute('CREATE INDEX idx_alert_events_item ON alert_events(inventory_item_id)');
    await db.execute('CREATE UNIQUE INDEX uq_alert_active_deduplication ON alert_events(deduplication_key) WHERE status IN (\'ACTIVE\',\'ACKNOWLEDGED\') AND deleted_at IS NULL');
  }
}
