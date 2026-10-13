import 'package:go_router/go_router.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/assets/screens/asset_detail_screen.dart';
import '../../features/assets/screens/asset_form_screen.dart';
import '../../features/assets/screens/asset_list_screen.dart';
import '../../features/assets/screens/asset_readings_screen.dart';
import '../../features/assets/screens/asset_tree_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/facilities/screens/facility_setup_screen.dart';
import '../../features/facilities/screens/location_form_screen.dart';
import '../../features/facilities/screens/location_list_screen.dart';
import '../../features/facilities/screens/location_tree_screen.dart';
import '../../features/inventory/screens/inventory_item_detail_screen.dart';
import '../../features/inventory/screens/inventory_item_form_screen.dart';
import '../../features/inventory/screens/inventory_list_screen.dart';
import '../../features/inventory/screens/stock_adjustment_screen.dart';
import '../../features/maintenance/screens/maintenance_plan_form_screen.dart';
import '../../features/maintenance/screens/maintenance_plan_list_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/purchases/screens/purchase_order_detail_screen.dart';
import '../../features/purchases/screens/purchase_order_form_screen.dart';
import '../../features/purchases/screens/purchase_order_list_screen.dart';
import '../../features/purchases/screens/receive_purchase_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/work_orders/screens/complete_task_screen.dart';
import '../../features/work_orders/screens/work_order_detail_screen.dart';
import '../../features/work_orders/screens/work_order_form_screen.dart';
import '../../features/work_orders/screens/work_order_list_screen.dart';
import '../storage/key_value_storage.dart';
import '../widgets/app_scaffold_shell.dart';

final router = GoRouter(
  initialLocation: KeyValueStorage.instance.isFirstRun ? '/onboarding' : '/',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/setup/facility',
      builder: (_, __) => const FacilitySetupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffoldShell(
          location: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const DashboardScreen(),
        ),
        // Assets
        GoRoute(
          path: '/assets',
          builder: (_, __) => const AssetListScreen(),
        ),
        GoRoute(
          path: '/assets/new',
          builder: (_, __) => const AssetFormScreen(),
        ),
        GoRoute(
          path: '/assets/tree',
          builder: (_, __) => const AssetTreeScreen(),
        ),
        GoRoute(
          path: '/assets/:id',
          builder: (_, state) => AssetDetailScreen(assetId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/assets/:id/edit',
          builder: (_, state) => AssetFormScreen(assetId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/assets/:id/readings',
          builder: (_, state) => AssetReadingsScreen(assetId: state.pathParameters['id']!),
        ),
        // Locations
        GoRoute(
          path: '/locations',
          builder: (_, __) => const LocationListScreen(),
        ),
        GoRoute(
          path: '/locations/new',
          builder: (_, __) => const LocationFormScreen(),
        ),
        GoRoute(
          path: '/locations/tree',
          builder: (_, __) => const LocationTreeScreen(),
        ),
        GoRoute(
          path: '/locations/:id/edit',
          builder: (_, state) => LocationFormScreen(locationId: state.pathParameters['id']!),
        ),
        // Maintenance Plans
        GoRoute(
          path: '/maintenance-plans',
          builder: (_, __) => const MaintenancePlanListScreen(),
        ),
        GoRoute(
          path: '/maintenance-plans/new',
          builder: (_, state) {
            final assetId = state.uri.queryParameters['assetId'] ?? '';
            return MaintenancePlanFormScreen(assetId: assetId);
          },
        ),
        GoRoute(
          path: '/maintenance-plans/:id/edit',
          builder: (_, state) {
            final assetId = state.uri.queryParameters['assetId'] ?? '';
            return MaintenancePlanFormScreen(assetId: assetId, planId: state.pathParameters['id']!);
          },
        ),
        // Work Orders
        GoRoute(
          path: '/work-orders',
          builder: (_, __) => const WorkOrderListScreen(),
        ),
        GoRoute(
          path: '/work-orders/new',
          builder: (_, __) => const WorkOrderFormScreen(),
        ),
        GoRoute(
          path: '/work-orders/:id',
          builder: (_, state) => WorkOrderDetailScreen(workOrderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/work-orders/:id/edit',
          builder: (_, state) => WorkOrderFormScreen(workOrderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/work-orders/:id/tasks/:taskId/complete',
          builder: (_, state) => CompleteTaskScreen(
            workOrderId: state.pathParameters['id']!,
            taskId: state.pathParameters['taskId']!,
          ),
        ),
        // Inventory
        GoRoute(
          path: '/inventory',
          builder: (_, __) => const InventoryListScreen(),
        ),
        GoRoute(
          path: '/inventory/new',
          builder: (_, __) => const InventoryItemFormScreen(),
        ),
        GoRoute(
          path: '/inventory/adjustment',
          builder: (_, __) => const StockAdjustmentScreen(),
        ),
        GoRoute(
          path: '/inventory/:id',
          builder: (_, state) => InventoryItemDetailScreen(itemId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/inventory/:id/edit',
          builder: (_, state) => InventoryItemFormScreen(itemId: state.pathParameters['id']!),
        ),
        // Purchases
        GoRoute(
          path: '/purchases',
          builder: (_, __) => const PurchaseOrderListScreen(),
        ),
        GoRoute(
          path: '/purchases/new',
          builder: (_, __) => const PurchaseOrderFormScreen(),
        ),
        GoRoute(
          path: '/purchases/:id',
          builder: (_, state) => PurchaseOrderDetailScreen(purchaseOrderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/purchases/:id/edit',
          builder: (_, state) => PurchaseOrderFormScreen(purchaseOrderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/purchases/:id/receive',
          builder: (_, state) => ReceivePurchaseScreen(purchaseOrderId: state.pathParameters['id']!),
        ),
        // Alerts & Settings
        GoRoute(
          path: '/alerts',
          builder: (_, __) => const AlertsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
