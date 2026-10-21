import 'package:go_router/go_router.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/assets/screens/asset_detail_screen.dart';
import '../../features/assets/screens/asset_form_screen.dart';
import '../../features/assets/screens/asset_list_screen.dart';
import '../../features/assets/screens/asset_meter_trend_screen.dart';
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
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/subscription/presentation/trial_intro_screen.dart';
import '../../features/work_orders/screens/complete_task_screen.dart';
import '../../features/work_orders/screens/correct_task_completion_screen.dart';
import '../../features/work_orders/screens/work_order_detail_screen.dart';
import '../../features/work_orders/screens/work_order_form_screen.dart';
import '../../features/work_orders/screens/work_order_list_screen.dart';
import '../../features/work_orders/screens/work_order_material_form_screen.dart';
import '../../features/work_orders/screens/work_order_task_form_screen.dart';
import '../widgets/app_scaffold_shell.dart';

GoRouter createAppRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(
      path: '/subscription',
      builder: (_, _) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/setup/facility',
      builder: (_, _) => const FacilitySetupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffoldShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        // Assets
        GoRoute(path: '/assets', builder: (_, _) => const AssetListScreen()),
        GoRoute(
          path: '/assets/new',
          builder: (_, _) => const AssetFormScreen(),
        ),
        GoRoute(
          path: '/assets/tree',
          builder: (_, _) => const AssetTreeScreen(),
        ),
        GoRoute(
          path: '/assets/:id',
          builder: (_, state) =>
              AssetDetailScreen(assetId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/assets/:id/edit',
          builder: (_, state) =>
              AssetFormScreen(assetId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/assets/:id/meter-trend',
          builder: (_, state) => AssetMeterTrendScreen(
            assetId: state.pathParameters['id']!,
            metricName: state.uri.queryParameters['metric'] ?? '',
            unit: state.uri.queryParameters['unit'] ?? '',
          ),
        ),
        GoRoute(
          path: '/assets/:id/readings',
          builder: (_, state) =>
              AssetReadingsScreen(assetId: state.pathParameters['id']!),
        ),
        // Locations
        GoRoute(
          path: '/locations',
          builder: (_, _) => const LocationListScreen(),
        ),
        GoRoute(
          path: '/locations/new',
          builder: (_, _) => const LocationFormScreen(),
        ),
        GoRoute(
          path: '/locations/tree',
          builder: (_, _) => const LocationTreeScreen(),
        ),
        GoRoute(
          path: '/locations/:id/edit',
          builder: (_, state) =>
              LocationFormScreen(locationId: state.pathParameters['id']!),
        ),
        // Maintenance Plans
        GoRoute(
          path: '/maintenance-plans',
          builder: (_, _) => const MaintenancePlanListScreen(),
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
            return MaintenancePlanFormScreen(
              assetId: assetId,
              planId: state.pathParameters['id']!,
            );
          },
        ),
        // Work Orders
        GoRoute(
          path: '/work-orders',
          builder: (_, _) => const WorkOrderListScreen(),
        ),
        GoRoute(
          path: '/work-orders/new',
          builder: (_, _) => const WorkOrderFormScreen(),
        ),
        GoRoute(
          path: '/work-orders/:id',
          builder: (_, state) =>
              WorkOrderDetailScreen(workOrderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/work-orders/:id/edit',
          builder: (_, state) =>
              WorkOrderFormScreen(workOrderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/work-orders/:id/tasks/new',
          builder: (_, state) =>
              WorkOrderTaskFormScreen(workOrderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/work-orders/:id/materials/new',
          builder: (_, state) => WorkOrderMaterialFormScreen(
            workOrderId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/work-orders/:id/tasks/:taskId/complete',
          builder: (_, state) => CompleteTaskScreen(
            workOrderId: state.pathParameters['id']!,
            taskId: state.pathParameters['taskId']!,
          ),
        ),
        GoRoute(
          path: '/work-orders/:id/tasks/:taskId/correct',
          builder: (_, state) => CorrectTaskCompletionScreen(
            workOrderId: state.pathParameters['id']!,
            taskId: state.pathParameters['taskId']!,
          ),
        ),
        // Inventory
        GoRoute(
          path: '/inventory',
          builder: (_, _) => const InventoryListScreen(),
        ),
        GoRoute(
          path: '/inventory/new',
          builder: (_, _) => const InventoryItemFormScreen(),
        ),
        GoRoute(
          path: '/inventory/adjustment',
          builder: (_, _) => const StockAdjustmentScreen(),
        ),
        GoRoute(
          path: '/inventory/:id',
          builder: (_, state) =>
              InventoryItemDetailScreen(itemId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/inventory/:id/edit',
          builder: (_, state) =>
              InventoryItemFormScreen(itemId: state.pathParameters['id']!),
        ),
        // Purchases
        GoRoute(
          path: '/purchases',
          builder: (_, _) => const PurchaseOrderListScreen(),
        ),
        GoRoute(
          path: '/purchases/new',
          builder: (_, _) => const PurchaseOrderFormScreen(),
        ),
        GoRoute(
          path: '/purchases/:id',
          builder: (_, state) => PurchaseOrderDetailScreen(
            purchaseOrderId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/purchases/:id/edit',
          builder: (_, state) => PurchaseOrderFormScreen(
            purchaseOrderId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/purchases/:id/receive',
          builder: (_, state) => ReceivePurchaseScreen(
            purchaseOrderId: state.pathParameters['id']!,
          ),
        ),
        // Alerts & Settings
        GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);
