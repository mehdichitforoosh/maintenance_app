# AGENTS.md — Maintenance Management App for a Small Workshop or Factory

## 1. Project mission

Build a practical, Persian-language, right-to-left (RTL) Flutter application for lightweight Computerized Maintenance Management (CMMS) for one small workshop or factory. The result must not be a UI-only demo or a skeleton: implement the data models, SQLite database, migrations, repositories, Riverpod providers/notifiers, domain logic, routing, and primary screens as one integrated application.

Before changing anything, inspect the existing project structure and `pubspec.yaml`. Do not rewrite existing working code without a reason. If code already exists, adapt it to these requirements. Avoid pinning package versions unnecessarily; remain compatible with the Flutter/Dart SDK installed for the project.

### Version 1 goals

- Manage one workshop/factory and a hierarchical location structure.
- Define equipment and sub-assets.
- Define maintenance plans based on calendar intervals, meter readings, conditions, one-time dates, or manual creation.
- Record asset readings such as operating hours, temperature, pressure, and vibration.
- Create work orders containing multiple tasks and multiple assets.
- Record task start/completion, outcome, findings, labor time, downtime, and consumed materials.
- Manage consumables/spare parts, inventory, and stock movements.
- Record purchase orders and full/partial goods receipts.
- Provide a daily dashboard for due/overdue work, open work orders, and low-stock items.
- Keep the architecture ready for future server synchronization. The current app must work offline.

### Version 1 scope boundaries

- The app is single-user and uses one warehouse, but the design should not block future expansion.
- Local SQLite is the only data source in version 1. “Sync-ready” does not mean that a backend or automatic synchronization must be implemented now.
- Users/technicians and roles, multiple warehouses, a standalone supplier module, payments, real IoT integrations, push notifications, attachments/photos, and advanced reporting are out of scope for now.
- Prioritize Android and iOS. `sqflite` is not, by itself, a general SQLite solution for Flutter Web; do not claim web support unless a separate storage adapter is designed and tested.

## 2. Technology and implementation rules

Use:

- Flutter and Dart with null safety.
- `sqflite` and `path` for SQLite.
- `flutter_riverpod` for state management and dependency injection. Do not use the legacy `provider` package.
- `go_router` for navigation.
- `google_fonts` with a readable font that supports Persian; use Vazirmatn if compatible with the package/API and the project.
- `fl_chart` for useful dashboard/report charts.
- `uuid` for UUID generation.
- `intl` for date/number formatting. If the app displays Jalali dates, use a compatible, reputable package such as `shamsi_date` and keep Jalali display logic separate from domain scheduling logic.
- `flutter_test` for tests. Use an in-memory database or temporary database path when useful for SQLite tests.

### Coding principles

1. Use a feature-first architecture; do not place every file in one generic `models/` directory.
2. Screens must not execute SQL directly. Use the path `Screen -> Riverpod provider/notifier -> Repository -> AppDatabase`.
3. Keep domain models independent from Flutter UI, with accurate and type-safe `toMap()`/`fromMap()` methods.
4. Run multi-step database changes inside `Database.transaction`.
5. Enable `PRAGMA foreign_keys = ON` in `onConfigure`.
6. Store timestamps as UTC ISO-8601 strings. Store date-only values as `YYYY-MM-DD` where only a calendar date matters. Apply local timezone and locale formatting only in the presentation layer.
7. Store enums as stable strings, not `Enum.toString()`. Centralize and test DB mappings.
8. Avoid physical deletion of historical business data. Use `deleted_at` for soft deletion where appropriate. Do not update or delete stock ledger entries; add reversal/adjustment entries instead.
9. Normal list queries must filter soft-deleted rows. Historical reports may include them according to an explicit policy.
10. Validate input in UI and repository/domain layers. Do not rely on SQLite `CHECK` constraints alone.
11. Do not leave decorative or inert buttons, filters, or actions. If a feature is out of scope, either omit it or show it as clearly disabled and marked “planned”.
12. Format code and run analysis/tests. Report unresolved failures honestly.

## 3. Recommended project structure

Preserve the existing project's conventions if present. If the project has no structure yet, start with this layout:

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
    app_startup.dart
  core/
    constants/
    errors/
    extensions/
    models/
      syncable_model.dart
    utils/
      date_utils.dart
      id_generator.dart
      validators.dart
    widgets/
      app_empty_state.dart
      app_error_state.dart
      app_loading.dart
      confirm_dialog.dart
      section_header.dart
  database/
    app_database.dart
    schema.dart
    migrations/
      migration.dart
  features/
    dashboard/
      screens/dashboard_screen.dart
      providers/dashboard_providers.dart
      repositories/dashboard_repository.dart
    facilities/
      models/facility.dart
      models/location.dart
      repositories/facility_repository.dart
      repositories/location_repository.dart
      providers/facility_providers.dart
      screens/facility_setup_screen.dart
      screens/location_list_screen.dart
      screens/location_form_screen.dart
    assets/
      models/asset.dart
      repositories/asset_repository.dart
      providers/asset_providers.dart
      screens/asset_list_screen.dart
      screens/asset_detail_screen.dart
      screens/asset_form_screen.dart
      screens/asset_tree_screen.dart
      screens/asset_readings_screen.dart
    maintenance/
      models/maintenance_plan.dart
      models/maintenance_plan_material.dart
      models/asset_reading.dart
      repositories/maintenance_plan_repository.dart
      repositories/asset_reading_repository.dart
      providers/maintenance_providers.dart
      services/maintenance_scheduler.dart
      services/condition_evaluator.dart
      screens/maintenance_plan_list_screen.dart
      screens/maintenance_plan_detail_screen.dart
      screens/maintenance_plan_form_screen.dart
    work_orders/
      models/work_order.dart
      models/work_order_task.dart
      models/work_order_material.dart
      repositories/work_order_repository.dart
      providers/work_order_providers.dart
      screens/work_order_list_screen.dart
      screens/work_order_detail_screen.dart
      screens/work_order_form_screen.dart
      screens/work_order_task_form_screen.dart
      screens/complete_task_screen.dart
    inventory/
      models/inventory_item.dart
      models/stock_transaction.dart
      repositories/inventory_repository.dart
      providers/inventory_providers.dart
      screens/inventory_list_screen.dart
      screens/inventory_item_detail_screen.dart
      screens/inventory_item_form_screen.dart
      screens/stock_transaction_list_screen.dart
      screens/stock_adjustment_screen.dart
    purchases/
      models/purchase_order.dart
      models/purchase_order_item.dart
      repositories/purchase_repository.dart
      providers/purchase_providers.dart
      screens/purchase_order_list_screen.dart
      screens/purchase_order_detail_screen.dart
      screens/purchase_order_form_screen.dart
      screens/receive_purchase_screen.dart
    alerts/
      models/alert_event.dart
      repositories/alert_repository.dart
      providers/alert_providers.dart
      screens/alerts_screen.dart
    settings/
      screens/settings_screen.dart
```

File names may change to fit the real project, but preserve feature boundaries and separation between UI, state, repositories, and database access.

## 4. UI and user experience

- Persian-language, RTL, mobile-first, light theme, clean Material 3 design.
- Use a Google Font with Persian glyph support; keep typography readable.
- Use compact cards and clear visual hierarchy; do not wrap every element in a Card.
- List screens need search/filtering and empty/loading/error states.
- Forms need Persian validation messages. Ask for confirmation before destructive, cancel, or completion actions where appropriate.
- Display dates in the appropriate Persian/Jalali format if configured, but retain the database storage contract.
- Show status using text and, where helpful, an icon as well as color; never rely on color alone.
- Suggested bottom navigation: **Home**, **Assets**, **Work Orders**, **Inventory**, **More**. “More” provides access to maintenance plans, purchases, alerts, locations, and settings.
- Long forms must scroll and respect `SafeArea` and the on-screen keyboard.
- Use `fl_chart` only when it adds value, such as completed/open work orders over time or material consumption. Do not fill charts with permanent fabricated data.
- The primary application must use real SQLite data, not fixed mock data. First-run seed data is acceptable only for necessary defaults or onboarding guidance.

## 5. Navigation and required screens

Use `MaterialApp.router` and `go_router`. At minimum, route to these screens:

- `/setup/facility`: initial workshop setup, shown if no Facility exists.
- `/`: dashboard.
- `/assets`: asset list, search, and filters by location/status.
- `/assets/new`, `/assets/:id`, `/assets/:id/edit`: create, details, and edit asset.
- `/assets/tree`: hierarchy view for locations/assets.
- `/assets/:id/readings`: asset reading history and entry.
- `/locations`, `/locations/new`, `/locations/:id/edit`: location management.
- `/maintenance-plans`: maintenance-plan list.
- `/maintenance-plans/new`, `/maintenance-plans/:id`, `/maintenance-plans/:id/edit`: plan form/details.
- `/work-orders`: work orders filtered by status/type/date.
- `/work-orders/new`, `/work-orders/:id`, `/work-orders/:id/edit`: create/details/edit work order.
- `/work-orders/:id/tasks/new`: add a task to a work order.
- `/work-orders/:id/tasks/:taskId/complete`: record task completion.
- `/inventory`: item list and current stock.
- `/inventory/new`, `/inventory/:id`, `/inventory/:id/edit`: item management.
- `/inventory/transactions`: stock ledger.
- `/inventory/adjustment`: increase/decrease stock correction.
- `/purchases`: purchase-order list.
- `/purchases/new`, `/purchases/:id`, `/purchases/:id/receive`: purchase creation, details, and receiving.
- `/alerts`: alerts filtered by status/severity.
- `/settings`: basic settings and facility information.

Use named/typed routes or clear route helpers and validate route IDs. If an ID does not exist, show a useful error state with a way back.

### Dashboard

The dashboard must use real repository data and include at least:

- Summary counts for due today, overdue tasks, open work orders, and low-stock items.
- Critical alerts and low-stock items.
- A compact “Today’s work” list with title, asset, due date, priority, and status.
- Shortcuts to create an asset, maintenance plan, work order, and inventory item.
- An optional light chart of completed/open work orders over a selected interval, only if real data exists.

### Asset details screen

Show:

- Code, name, type, status, location, and parent asset.
- Manufacturer/model/serial number when present.
- Related maintenance plans.
- Recent/important work orders.
- Recent readings and an action to add a reading.
- Links to parent and child assets.

### Work order details screen

Show:

- Work order details and status.
- Multiple tasks; each task can target an asset and optionally originate from a plan.
- Ability to add manual tasks or select an existing maintenance plan.
- Task start/completion, findings, result, labor time, downtime, and consumed materials.
- Total materials/cost where a valid cost is available.
- Do not allow final closure while open tasks remain, unless a defined policy explicitly cancels/skips them.

## 6. Data model and shared contracts

### 6.1 Common fields

All primary tables should include these fields where relevant:

- `id TEXT PRIMARY KEY`: device-generated UUID.
- `created_at TEXT NOT NULL`: UTC timestamp.
- `updated_at TEXT NOT NULL`: UTC timestamp of latest change.
- `deleted_at TEXT NULL`: soft deletion for eligible records.
- `sync_status TEXT NOT NULL DEFAULT 'pending'`: `pending`, `synced`, or `conflict`.

These fields support future synchronization but do not implement it. A future sync layer will likely require server IDs/versions, sync cursors, idempotency handling, and conflict-resolution policies.

### 6.2 Enum mapping

Use stable uppercase snake-case strings in SQLite. Examples:

- `underMaintenance` -> `UNDER_MAINTENANCE`
- `maintenanceOverdue` -> `MAINTENANCE_OVERDUE`
- `partiallyReceived` -> `PARTIALLY_RECEIVED`

Do not rename Dart enum values without a data migration. Unknown DB enum values must be handled with an explicit safe fallback or a clear `FormatException`; never silently map important values such as stock transaction types to an incorrect value.

### 6.3 Entities and business rules

#### Facility

- `id`, `name`, optional `description`, optional `address`, timestamps, optional `deleted_at`, `sync_status`.
- Usually only one Facility exists in version 1. Provide repository methods to get/create/update the primary facility.

#### Location

- `id`, `facility_id`, optional `parent_location_id`, `name`, optional `code`, optional `description`, `is_active`, timestamps, deletion/sync fields.
- `parent_location_id` references `locations`.
- Prevent location cycles. A parent must belong to the same Facility.

#### Asset

- `id`, `facility_id`, optional `location_id`, optional `parent_asset_id`, `name`, `code`, `asset_type`, optional `manufacturer`, optional `model`, optional `serial_number`, optional `installation_date`, optional `commissioning_date`, `status`, optional `description`, timestamps, deletion/sync fields.
- Statuses: `ACTIVE`, `INACTIVE`, `UNDER_MAINTENANCE`, `RETIRED`.
- Initial types: `MACHINE`, `MOTOR`, `PUMP`, `COMPRESSOR`, `ELECTRICAL`, `OTHER`. Keep the design open to custom types later.
- `code` must be unique within a Facility.
- Prevent cycles in `parent_asset_id`. Facility, location, and parent asset must belong to the same Facility.

#### MaintenancePlan

- `id`, `asset_id`, `title`, optional `description`, `activity_type`, `priority`, `schedule_type`.
- Calendar fields: `calendar_interval_value`, `calendar_interval_unit`.
- Meter fields: `meter_name`, `meter_interval`, `meter_unit`, `last_completed_meter_value`, `next_due_meter_value`.
- Condition field: `condition_config_json`.
- One-time field: `one_time_due_at`.
- General fields: `start_date`, `next_due_at`, `last_completed_at`, `schedule_anchor`, `is_active`, timestamps, deletion/sync fields.
- Activity types: `INSPECTION`, `LUBRICATION`, `REPLACEMENT`, `CLEANING`, `CALIBRATION`, `TESTING`, `REPAIR`, `OTHER`.
- Priorities: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.
- Schedule types: `CALENDAR`, `METER`, `CONDITION`, `ONE_TIME`, `MANUAL`.
- Calendar units: `DAY`, `WEEK`, `MONTH`, `YEAR`.
- Schedule anchors: `COMPLETION_DATE`, `PREVIOUS_DUE_DATE`.
- `CALENDAR` requires a positive interval, a valid unit, and an initial due date that can be resolved from `next_due_at` or `start_date`. `METER` requires a metric name, positive interval, and unit. `CONDITION` requires valid JSON. `ONE_TIME` requires a due date. `MANUAL` has no required automatic due date. Validate these rules in the repository/domain layer as well as the database.
- `next_due_at` is useful for calendar/one-time plans. Do not interpret it as the live due state for meter/condition plans.

#### AssetReading

- `id`, `asset_id`, `metric_name`, numeric `value`, `unit`, `recorded_at`, optional `notes`, timestamps, deletion/sync fields.
- Example metrics: `operating_hours`, `temperature`, `pressure`, `vibration`.
- For cumulative readings such as operating hours, validate that readings do not unexpectedly decrease, or provide an explicit counter-reset/replacement workflow.

#### WorkOrder

- `id`, `facility_id`, `work_order_number`, `title`, optional `description`, `work_order_type`, `priority`, `status`, optional `scheduled_at`, `started_at`, `completed_at`, `closed_at`, optional `notes`, timestamps, deletion/sync fields.
- Types: `PREVENTIVE`, `CORRECTIVE`, `EMERGENCY`.
- Statuses: `DRAFT`, `OPEN`, `IN_PROGRESS`, `ON_HOLD`, `COMPLETED`, `CANCELLED`.
- The display number is unique within a Facility; the UUID remains the primary key.
- A work order can contain multiple tasks and cover multiple assets.

#### WorkOrderTask

- `id`, `work_order_id`, `asset_id`, optional `maintenance_plan_id`, `title`, optional `description`, `activity_type`, `status`, optional `result`.
- Times: optional `scheduled_at`, `planned_due_at`, `started_at`, `completed_at`.
- Meter snapshot: optional `planned_meter_value`, `completion_meter_value`, `completion_meter_name`, `completion_meter_unit`.
- Condition trigger: optional `triggering_reading_id`.
- Duplicate prevention: optional `source_occurrence_key`.
- Reporting: optional `findings`, `failure_description`, `follow_up_required`, optional `labor_minutes`, `downtime_minutes`, `notes`, timestamps, deletion/sync fields.
- Statuses: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `SKIPPED`, `CANCELLED`.
- Results: `SUCCESS`, `ISSUE_FOUND`, `FAILED`, `FOLLOW_UP_REQUIRED`.
- `title`, `description`, `activity_type`, and planned due information are snapshots. Editing a Plan must not rewrite existing execution history.
- For tasks created from a Plan, add a partial unique index over `(maintenance_plan_id, source_occurrence_key)`, excluding soft-deleted rows.

#### InventoryItem

- `id`, `name`, `code`, `item_type`, `unit`, optional `description`, `minimum_stock`, optional `default_unit_cost`, `is_active`, timestamps, deletion/sync fields.
- Types: `CONSUMABLE`, `SPARE_PART`.
- Item codes must be unique. Every item has one base unit; all movements for that item use the same unit.

#### MaintenancePlanMaterial

- `id`, `maintenance_plan_id`, `item_id`, `planned_quantity > 0`, optional `notes`, timestamps, deletion/sync fields.
- Many-to-many bridge between maintenance plans and inventory items. In version 1, one active row per item per plan is sufficient.

#### WorkOrderMaterial

- `id`, `work_order_task_id`, `item_id`, optional `planned_quantity`, `actual_quantity`, `unit_cost_at_use`, optional `notes`, timestamps, deletion/sync fields.
- Quantity and cost values cannot be negative.
- This records planned/actual usage. Inventory changes are represented by `StockTransaction`.

#### PurchaseOrder / PurchaseOrderItem

- `PurchaseOrder`: `id`, `facility_id`, `purchase_order_number`, optional `supplier_name`, `order_date`, optional `expected_date`, `status`, optional `notes`, timestamps, deletion/sync fields.
- Statuses: `DRAFT`, `ORDERED`, `PARTIALLY_RECEIVED`, `RECEIVED`, `CANCELLED`.
- `PurchaseOrderItem`: `id`, `purchase_order_id`, `item_id`, `ordered_quantity > 0`, `unit_price >= 0`, optional `notes`, timestamps, deletion/sync fields.
- Do not store received quantity as duplicated state; calculate it from receipt stock transactions linked to that purchase order item.

#### StockTransaction

- `id`, `item_id`, `transaction_type`, `quantity > 0`, optional `unit_cost`, `transaction_date`, optional `purchase_order_item_id`, optional `work_order_material_id`, optional `notes`, timestamps, deletion/sync fields.
- Types: `PURCHASE_RECEIPT`, `MAINTENANCE_CONSUMPTION`, `ADJUSTMENT_IN`, `ADJUSTMENT_OUT`, `RETURN`.
- `PURCHASE_RECEIPT` must reference `purchase_order_item_id`.
- `MAINTENANCE_CONSUMPTION` and `RETURN` must reference `work_order_material_id`.
- `ADJUSTMENT_IN`/`ADJUSTMENT_OUT` require neither reference.
- Transaction type determines stock direction; quantity is always positive.
- Treat the stock ledger as append-only. Correct a previous movement with a reversing/adjustment transaction, not by updating/deleting the old movement.
- Calculate current stock as receipts/positive adjustments/returns minus consumption/negative adjustments. A repository query is enough for the MVP. Prevent negative stock.

#### AlertEvent

- `id`, `facility_id`, `alert_type`, `severity`, `status`, `title`, optional `message`, optional `asset_id`, `maintenance_plan_id`, `work_order_task_id`, `inventory_item_id`, `deduplication_key`, `triggered_at`, optional `acknowledged_at`, `resolved_at`, timestamps, deletion/sync fields.
- Types: `MAINTENANCE_DUE`, `MAINTENANCE_OVERDUE`, `CONDITION_TRIGGERED`, `LOW_STOCK`, `WORK_ORDER_OVERDUE`.
- Severity: `INFO`, `WARNING`, `CRITICAL`.
- Status: `ACTIVE`, `ACKNOWLEDGED`, `RESOLVED`, `DISMISSED`.
- Use a unique key to prevent duplicate active alerts. A new event may be created after the previous event is resolved/dismissed.
- Derive the daily summary at display time; do not create a separate table for the daily summary itself.

## 7. SQLite schema reference: required tables and constraints

Create all tables in migration version 1. Include the common timestamp/deletion/sync fields as applicable. Foreign keys must be enabled. Add indexes for common queries. Create tables in this order so dependencies stay clear:

1. `facilities`
2. `locations`
3. `assets`
4. `maintenance_plans`
5. `asset_readings`
6. `inventory_items`
7. `maintenance_plan_materials`
8. `work_orders`
9. `work_order_tasks`
10. `work_order_materials`
11. `purchase_orders`
12. `purchase_order_items`
13. `stock_transactions`
14. `alert_events`

### `facilities`

```sql
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
);
```

### `locations`

```sql
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
);
```

### `assets`

```sql
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
);
```

### `maintenance_plans`

```sql
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
);
```

### `asset_readings`

```sql
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
);
```

### `inventory_items`

```sql
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
);
```

### `maintenance_plan_materials`

```sql
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
);
```

### `work_orders`

```sql
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
);
```

### `work_order_tasks`

```sql
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
);
```

### `work_order_materials`

```sql
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
);
```

### `purchase_orders`

```sql
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
);
```

### `purchase_order_items`

```sql
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
);
```

### `stock_transactions`

```sql
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
);
```

### `alert_events`

```sql
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
);
```

### Required indexes

Create all indexes after table creation:

```sql
CREATE INDEX idx_locations_facility ON locations(facility_id);
CREATE INDEX idx_locations_parent ON locations(parent_location_id);

CREATE INDEX idx_assets_facility ON assets(facility_id);
CREATE INDEX idx_assets_location ON assets(location_id);
CREATE INDEX idx_assets_parent ON assets(parent_asset_id);
CREATE INDEX idx_assets_status ON assets(status);

CREATE INDEX idx_maintenance_plans_asset ON maintenance_plans(asset_id);
CREATE INDEX idx_maintenance_plans_due ON maintenance_plans(next_due_at)
  WHERE is_active = 1 AND deleted_at IS NULL;
CREATE INDEX idx_maintenance_plans_type ON maintenance_plans(schedule_type);

CREATE INDEX idx_asset_readings_asset_metric_time
  ON asset_readings(asset_id, metric_name, recorded_at);
CREATE INDEX idx_asset_readings_sync ON asset_readings(sync_status)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_inventory_items_name ON inventory_items(name);
CREATE INDEX idx_inventory_items_active ON inventory_items(is_active);

CREATE INDEX idx_plan_materials_plan ON maintenance_plan_materials(maintenance_plan_id);
CREATE INDEX idx_plan_materials_item ON maintenance_plan_materials(item_id);

CREATE INDEX idx_work_orders_facility_status ON work_orders(facility_id, status);
CREATE INDEX idx_work_orders_scheduled ON work_orders(scheduled_at);
CREATE INDEX idx_work_orders_updated ON work_orders(updated_at);

CREATE INDEX idx_work_order_tasks_order ON work_order_tasks(work_order_id);
CREATE INDEX idx_work_order_tasks_asset ON work_order_tasks(asset_id);
CREATE INDEX idx_work_order_tasks_plan ON work_order_tasks(maintenance_plan_id);
CREATE INDEX idx_work_order_tasks_status ON work_order_tasks(status);
CREATE INDEX idx_work_order_tasks_due ON work_order_tasks(planned_due_at);
CREATE UNIQUE INDEX uq_work_order_task_occurrence
  ON work_order_tasks(maintenance_plan_id, source_occurrence_key)
  WHERE maintenance_plan_id IS NOT NULL
    AND source_occurrence_key IS NOT NULL
    AND deleted_at IS NULL;

CREATE INDEX idx_work_order_materials_task ON work_order_materials(work_order_task_id);
CREATE INDEX idx_work_order_materials_item ON work_order_materials(item_id);

CREATE INDEX idx_purchase_orders_facility_status ON purchase_orders(facility_id, status);
CREATE INDEX idx_purchase_orders_order_date ON purchase_orders(order_date);
CREATE INDEX idx_purchase_order_items_order ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_purchase_order_items_item ON purchase_order_items(item_id);

CREATE INDEX idx_stock_transactions_item_date ON stock_transactions(item_id, transaction_date);
CREATE INDEX idx_stock_transactions_purchase_item ON stock_transactions(purchase_order_item_id);
CREATE INDEX idx_stock_transactions_work_order_material ON stock_transactions(work_order_material_id);

CREATE INDEX idx_alert_events_status_time ON alert_events(status, triggered_at);
CREATE INDEX idx_alert_events_facility ON alert_events(facility_id, status);
CREATE INDEX idx_alert_events_asset ON alert_events(asset_id);
CREATE INDEX idx_alert_events_item ON alert_events(inventory_item_id);
CREATE UNIQUE INDEX uq_alert_active_deduplication
  ON alert_events(deduplication_key)
  WHERE status IN ('ACTIVE','ACKNOWLEDGED') AND deleted_at IS NULL;
```

## 8. AppDatabase and migrations

- Keep `AppDatabase` as a singleton or provider-owned dependency while preserving testability.
- Maintain a `databaseVersion`.
- Execute `PRAGMA foreign_keys = ON` inside `onConfigure`.
- In `onCreate`, create all tables in the order above, then create indexes.
- `onUpgrade` must run numbered, additive migrations; never delete user data during a normal upgrade.
- If an existing app database is present, inspect its current version/schema and create compatible migrations. Do not blindly replace an existing version-1 migration.
- Test database creation, run `PRAGMA foreign_key_check`, and assert that it returns no violations.
- Stock movements must not be soft-deleted in ordinary workflows. `deleted_at` may exist for schema consistency, but repositories must prohibit ordinary edits/deletions of stock ledger rows.

## 9. Required repositories and expected APIs

Repositories translate database exceptions into domain errors/results suitable for user-facing messages. Never put raw SQL in screens or widgets.

### FacilityRepository

- `Future<Facility?> getPrimaryFacility()`
- `Future<Facility> createFacility(...)`
- `Future<Facility> updateFacility(Facility facility)`
- `Future<bool> hasFacility()`

### LocationRepository

- List locations by Facility.
- Get a Location by ID.
- Create, update, and deactivate locations.
- Search and build a tree from a flat list.
- Reject invalid parents, parents from another Facility, and cycles.

### AssetRepository

- List assets with search/pagination or bounded results and filters by name/code/location/status.
- Get an Asset plus parent/children.
- CRUD, deactivate, and retire assets.
- Enforce code uniqueness within a Facility.
- Validate that the facility, location, and parent asset belong to the same Facility.

### MaintenancePlanRepository

- CRUD maintenance plans.
- List plans for an asset.
- List active and due plans.
- Add/update/soft-delete plan materials.
- Update `next_due_at`, `last_completed_at`, `last_completed_meter_value`, and `next_due_meter_value` only through the scheduler/completion workflow.

### AssetReadingRepository

- Insert a reading.
- Get the latest reading for an `asset_id + metric_name` pair.
- Retrieve readings over a date range.
- Validate cumulative meter progression or support an explicit counter-reset event.

### WorkOrderRepository

- CRUD work order headers.
- Create a work order and its multiple tasks transactionally.
- List/filter by status, type, date, and asset.
- Start a work order/task.
- Complete a task with result and meter snapshots.
- Close a work order only after validating its task statuses.
- Generate automatic work orders/tasks idempotently using `source_occurrence_key`.
- Write all material consumption and associated stock movements in a single database transaction.

### InventoryRepository

- CRUD inventory items.
- Calculate each item's current stock from the ledger.
- List low-stock items.
- Retrieve inbound/outbound history.
- Correct inventory only by creating `ADJUSTMENT_IN` or `ADJUSTMENT_OUT` transactions.
- Prevent stock from becoming negative during consumption.
- Snapshot the unit cost at consumption time. For the MVP, a moving-average cost calculated from receipts is acceptable; implement and test the costing policy centrally.

### PurchaseRepository

- Create/update orders according to permitted statuses.
- Add/edit lines before receiving.
- Calculate received quantity from linked `PURCHASE_RECEIPT` transactions.
- Receive partially/fully in a DB transaction: validate remaining quantity, insert stock transactions, update order status.
- Do not allow invalid receipts for cancelled/fully received orders.

### AlertRepository

- List alerts with status/severity/type filters.
- Acknowledge, resolve, and dismiss alerts.
- Reconcile alerts using stable deduplication keys; dashboard refresh must not generate duplicates.
- Compare low-stock alerts with current calculated inventory.

### DashboardRepository

- Count items due today, overdue items, open work orders, and low-stock items.
- Return a short list of today's tasks and important alerts.
- Use real queries for chart data. Show an empty state if there is no data.

## 10. Riverpod providers/notifiers

Use `flutter_riverpod`. Do not add the separate legacy `provider` package.

- `appDatabaseProvider`: database dependency.
- Repository providers that depend on `appDatabaseProvider`.
- `primaryFacilityProvider`, `locationsProvider`, `assetsProvider`, `assetDetailProvider`.
- `maintenancePlansProvider`, `maintenancePlanDetailProvider`, `assetReadingsProvider`.
- `workOrdersProvider`, `workOrderDetailProvider`.
- `inventoryItemsProvider`, `inventoryStockProvider`, `stockTransactionsProvider`.
- `purchaseOrdersProvider`, `purchaseOrderDetailProvider`.
- `alertsProvider`, `dashboardSummaryProvider`, `dashboardTasksProvider`.
- Lists may use `FutureProvider` or `AsyncNotifier`. Put write operations in a Notifier/controller or suitable action layer.
- After a successful mutation, invalidate/refresh related providers so the UI reflects the database state.
- Cover loading/error/empty/success states in screens.
- Do not use global mutable lists or duplicate app state inside widgets.
- Providers must be overridable in tests.

## 11. Maintenance scheduling

Put scheduling logic in `MaintenanceScheduler`, not in screens and not in model constructors.

### Calendar scheduling

- `CALENDAR`: due by interval + unit.
- `ONE_TIME`: due only at `one_time_due_at`.
- `MANUAL`: created by a user and has no automatic due date.
- Do not use `DateTime.add(Duration(days: 30))` as a substitute for a calendar month. Monthly/yearly helpers must correctly clamp at the last valid day of a month and handle leap years.
- `COMPLETION_DATE`: calculate the next due date from the actual completion date/time.
- `PREVIOUS_DUE_DATE`: advance from previous planned due dates. Avoid generating a burst of many overdue tasks after late completion. MVP default: after completion, save the first future due date and do not bulk-create missed past occurrences.

### Meter scheduling

- A Plan specifies `metric_name`, interval, and unit.
- `next_due_meter_value` is the target value.
- When a Reading reaches the target, create one Task for that occurrence; its occurrence key must encode the target, e.g. `meter:operating_hours:1500`.
- On task completion, save the actual `completion_meter_value` to the Task, then update the Plan: `last_completed_meter_value = completion_meter_value` and `next_due_meter_value = completion_meter_value + meter_interval`.
- If the meter passes multiple due thresholds, default to creating only one open Task per Plan. After completion, base the next target on the actual completion reading.

### Condition scheduling

- Validate `condition_config_json`. Minimum contract:
  `{"metric":"temperature","operator":"gte","threshold":80,"unit":"celsius"}`
- MVP operators: `gt`, `gte`, `lt`, `lte`, `eq`.
- Reading units must be compatible with the condition's unit.
- Create an alert/task only when a condition episode begins, not for every later reading that remains over/under the threshold.
- While a Task for the same episode remains open, do not create another condition Task for the same Plan.
- Condition scheduling does not imply a sensor integration. In the MVP, readings can be entered manually.

### Task and alert generation

- Run the scheduler on dashboard launch and relevant events. All operations must be idempotent.
- The MVP does not need a guaranteed background job; mobile OSes may suspend the app. Reconcile when the app returns to the foreground/starts, and after a Reading is recorded or a Task is completed.
- Use stable calendar occurrence keys such as `calendar:2026-10-15`.
- Use `one-time:<due-date-or-timestamp>` for one-time plans.
- Use `meter:<metric>:<target-value>` for meter plans.
- Use one stable key for a single condition episode.
- Alerts and work orders are different concepts: alerts inform the user; tasks/work orders record executable work and its history.

## 12. Inventory, purchasing, and costs

- Each item has one base unit; all quantities for that item use that unit.
- `StockTransaction.quantity` is always positive; `transaction_type` determines direction.
- Current stock = `PURCHASE_RECEIPT + ADJUSTMENT_IN + RETURN - MAINTENANCE_CONSUMPTION - ADJUSTMENT_OUT`, filtering `deleted_at IS NULL`.
- `RETURN` must reference a WorkOrderMaterial and use the appropriate unit cost.
- A purchase-order status change alone must not increase stock. A real stock transaction must be created on receipt.
- Receiving (partial or complete) and material consumption must be atomic transactions.
- Prevent consumption beyond available stock. If stock is insufficient during Task completion, show a clear error and do not commit partial changes.
- Snapshot `unit_cost_at_use` on WorkOrderMaterial. Use a consistent costing method (moving average is preferred for the MVP); historical cost must not change when an item's price changes later.
- In the MVP, PurchaseOrderItem and WorkOrderMaterial are unique per item in their parent. Add schema migrations if multiple batches/consumption lines become necessary.

## 13. Dashboard and reporting

Dashboard sections:

1. Summary cards: due today, overdue, open work orders, low-stock items.
2. “Today's work”: tasks due today that are not in a terminal status.
3. “Overdue”: tasks/plans whose due dates have passed and have no valid completion.
4. “Alerts”: active/critical alerts.
5. Optional `fl_chart`: daily/weekly completed work orders or material usage, based only on real queries.

Minimum reports:

- Work order history for an asset.
- Latest readings for an asset.
- Current inventory and low-stock items.
- Stock movement history over a date range.
- Purchases and quantities received per purchase order.
- Due and overdue maintenance work.

Use the user's local calendar-day boundaries when calculating “today”. Comparing a UTC timestamp string directly against a `YYYY-MM-DD` value is not sufficient.

## 14. Domain validation

- Asset/item names and codes must not be blank; codes must be unique within their defined scope.
- Location/asset parent hierarchies must not contain cycles.
- Locations/assets must belong to the same Facility as their parents and relationships.
- Calendar and meter intervals must be positive.
- Meter readings should not be negative unless the metric permits it; define metric-specific rules.
- `started_at` must not be after `completed_at`.
- `labor_minutes` and `downtime_minutes` cannot be negative.
- Completed Tasks must have `completed_at` and a result according to the domain policy.
- A completed Work Order must not have open Tasks.
- Received quantity cannot exceed the order's remaining quantity unless explicit over-delivery support is implemented.
- Negative stock is prohibited.
- Condition JSON must parse and include the required metric/operator/threshold/unit.
- Unknown enum values must not silently turn into incorrect domain values.

## 15. Required tests

Create at least the following tests.

### Database

- Create the full schema and verify all 14 tables exist.
- `PRAGMA foreign_key_check` returns no rows.
- Verify CHECK/UNIQUE/foreign-key constraints.
- Migrations preserve existing data.

### Repositories

- Facility/Location/Asset CRUD.
- Reject duplicate codes, invalid parents, and cycles.
- Create a Work Order with multiple Tasks.
- Record/complete a Task with actual material consumption.
- Full rollback if any part of a material/stock transaction fails.
- Partial and full purchase receipt calculates received quantity correctly.
- Current stock is calculated correctly from transactions.
- Negative stock is rejected.
- Soft deletion works for normal entities, and the ledger is not deleted.

### Scheduler

- Calendar day/week/month/year intervals, including short months and leap years.
- One-time plan produces its Task at most once.
- Re-running the scheduler does not create duplicate Tasks.
- Meter plan triggers only when the target is reached.
- Completing a meter Task uses the actual completion value for the next target.
- Consecutive condition readings do not create duplicate Tasks for one episode.
- Inactive plans do not generate Tasks.

### UI

- Empty/loading/error states at least for dashboard, assets, work orders, and inventory.
- Form validation.
- Routes with invalid IDs.
- Correct provider refresh after status changes/mutations.

## 16. Acceptance criteria

The work is complete only when:

- The project runs and the main screens are reachable through the router.
- Initial Facility setup works and does not appear again once a Facility exists, unless the Facility is missing.
- Asset, location, maintenance-plan, work-order, and inventory CRUD work with real SQLite data.
- A calendar maintenance plan can generate a Work Order/Task, and re-running the scheduler does not create duplicates.
- A Task can record completion results and actual material consumption.
- Purchase receipt and consumption correctly affect inventory, and multi-step actions are atomic.
- The dashboard shows real data.
- Filters, searches, forms, and routes work.
- All 14 tables and required indexes exist.
- No important button is inert, no permanent mock data appears in primary screens, and no SQL remains inside UI code.
- `flutter analyze` and tests have been run. Report any remaining limitation/failure explicitly.

## 17. Recommended implementation sequence for the agent

Proceed in order and compile/test after each stage. Do not generate a large amount of code at once without validation.

1. Inspect the existing project, `pubspec.yaml`, and SDK version; add required dependencies.
2. Create core utilities, enum mappings, UUID/date helpers, and RTL/theme setup.
3. Create the complete schema and `AppDatabase`; test all 14 tables, indexes, and foreign keys.
4. Implement all Dart models and test `toMap()`/`fromMap()`.
5. Implement repositories and repository tests.
6. Implement `MaintenanceScheduler` and `ConditionEvaluator`; test idempotency.
7. Define Riverpod providers/notifiers and refresh/invalidation strategy.
8. Define router, root layout, and initial Facility setup.
9. Build screens in this order: Facility/Location/Assets, Maintenance Plans/Readings, Work Orders, Inventory, Purchases, Alerts, Dashboard.
10. Add `fl_chart` charts only for real dashboard/report data.
11. Run formatting, `flutter analyze`, and tests; fix issues.
12. In the final response, report files created, completed functionality, run instructions, analysis/test results, and remaining work accurately. Do not claim an unimplemented feature is complete.

## 18. Final instruction to the agent

Use this document to build a real, runnable initial application. Do not deliver only suggestions, pseudocode, or a few sample files. First inspect the existing project, then implement it incrementally. If a minor detail is unspecified, make a conservative, extensible decision and document it in the final report; do not ask the user questions for details that do not block progress. Never delete user data during migrations, and keep multi-table operations atomic.
