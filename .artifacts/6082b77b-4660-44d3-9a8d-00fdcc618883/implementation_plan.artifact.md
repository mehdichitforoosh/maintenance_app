# Implementation Plan - Maintenance Management App (CMMS)

Build a practical, Persian-language, right-to-left (RTL) Flutter CMMS application for small workshops and factories as specified in `AGENTS.md`. The implementation will replace legacy template tables with the required 14-table SQLite schema, robust domain models, transactional repositories, Riverpod state management, maintenance scheduler, and all primary screens.

## User Review Required

> [!IMPORTANT]
> - **Database Schema**: Replaces legacy template tables with the 14 required tables (`facilities`, `locations`, `assets`, `maintenance_plans`, `asset_readings`, `inventory_items`, `maintenance_plan_materials`, `work_orders`, `work_order_tasks`, `work_order_materials`, `purchase_orders`, `purchase_order_items`, `stock_transactions`, `alert_events`) and their strict constraints & indexes.
> - **Localization & RTL**: Uses Vazirmatn font, Persian localizations, date/number formatting, and right-to-left directionality.
> - **Offline-First / Sync-Ready**: Implements common fields (`id`, timestamps, `deleted_at`, `sync_status`) across all tables.

## Open Questions

- None. All requirements are clearly defined in `AGENTS.md`.

## Proposed Changes

### Core & Database
- Remove legacy template table files (`lib/core/storage/database/tables/*`).
- Create `AppDatabase` with `databaseVersion`, foreign key configuration (`PRAGMA foreign_keys = ON`), full 14-table schema creation, and additive migrations.
- Create core utilities, enum mappings (uppercase snake-case strings), UUID generator, date helpers (`date_utils.dart`), and validators.

### Domain Models & Enums
- Implement type-safe domain models for all 14 entities with `toMap()` and `fromMap()` methods.
- Implement stable string mapping for enums (`AssetType`, `AssetStatus`, `ActivityType`, `Priority`, `ScheduleType`, `CalendarUnit`, `ScheduleAnchor`, `WorkOrderType`, `WorkOrderStatus`, `TaskStatus`, `TaskResult`, `ItemType`, `PurchaseOrderStatus`, `TransactionType`, `AlertType`, `AlertSeverity`, `AlertStatus`).

### Repositories
- Implement repositories handling database operations and mapping database exceptions to domain errors:
  - `FacilityRepository`
  - `LocationRepository`
  - `AssetRepository`
  - `MaintenancePlanRepository`
  - `AssetReadingRepository`
  - `WorkOrderRepository`
  - `InventoryRepository`
  - `PurchaseRepository`
  - `AlertRepository`
  - `DashboardRepository`

### Business Logic & Services
- Implement `MaintenanceScheduler` handling calendar, meter, condition, one-time, and manual scheduling idempotently with occurrence keys.
- Implement `ConditionEvaluator` for condition-based triggers (`gt`, `gte`, `lt`, `lte`, `eq`).

### State Management & Navigation
- Configure `flutter_riverpod` providers and notifiers for all repositories and active states.
- Configure `go_router` supporting all required routes (`/`, `/setup/facility`, `/assets`, `/work-orders`, `/inventory`, `/purchases`, `/alerts`, `/settings`, etc.).

### Presentation Layer & UI
- Configure MaterialApp with RTL, Vazirmatn font, light theme, and Persian localizations.
- Build screens:
  - Facility Setup screen & initial onboarding check.
  - Dashboard screen (summary cards, today's work, overdue tasks, alerts, quick shortcuts, fl_charting).
  - Assets feature (list, details, form, tree, readings).
  - Locations feature (list, form).
  - Maintenance Plans feature (list, details, form).
  - Work Orders feature (list, details, form, task creation, task completion).
  - Inventory feature (list, details, form, transactions ledger, stock adjustments).
  - Purchases feature (list, details, form, receiving).
  - Alerts screen.
  - Settings screen.

### Testing
- Unit & integration tests for schema creation, foreign key constraints, repository operations, inventory ledger calculations, and maintenance scheduling idempotency.

## Verification Plan

### Automated Tests
- Run `flutter test` for database constraints, repository methods, and scheduling logic.
- Run `flutter analyze` to ensure zero compilation or linter errors.

### Manual Verification
- Deploy/run the app, complete initial facility setup, create locations, assets, maintenance plans, record readings, generate work orders, record task completion with consumed materials, receive purchase orders, and inspect inventory & dashboard.
