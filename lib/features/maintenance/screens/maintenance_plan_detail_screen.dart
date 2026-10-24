import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../assets/providers/asset_providers.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../../work_orders/providers/work_order_providers.dart';
import '../providers/maintenance_providers.dart';
import 'widgets/maintenance_plan_detail_sections.dart';
import 'widgets/maintenance_plan_report.dart';

class MaintenancePlanDetailScreen extends ConsumerWidget {
  final String planId;

  const MaintenancePlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(maintenancePlanDetailProvider(planId));

    return planAsync.when(
      loading: () => const Scaffold(body: AppLoading()),
      error: (error, _) =>
          Scaffold(body: AppErrorState(message: error.toString())),
      data: (plan) {
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('برنامه نگهداری')),
            body: AppEmptyState(
              title: 'برنامه یافت نشد',
              message: 'این برنامه حذف شده یا دیگر در دسترس نیست.',
              actionLabel: 'بازگشت به فهرست',
              onActionPressed: () => context.go('/maintenance-plans'),
            ),
          );
        }

        final assetAsync = ref.watch(assetDetailProvider(plan.assetId));
        final materialsAsync = ref.watch(planMaterialsProvider(plan.id));
        final tasksAsync = ref.watch(maintenancePlanTasksProvider(plan.id));
        final itemsAsync = ref.watch(allInventoryItemsProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.title),
            actions: [
              IconButton(
                tooltip: 'ویرایش برنامه',
                icon: const Icon(EneftyIcons.edit_2_outline),
                onPressed: () => context.push(
                  '/maintenance-plans/${plan.id}/edit?assetId=${plan.assetId}',
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MaintenancePlanSummary(plan: plan),
              const SizedBox(height: 16),
              assetAsync.when(
                data: (asset) => MaintenancePlanAssetCard(asset: asset),
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
              const SizedBox(height: 24),
              tasksAsync.when(
                data: (tasks) => MaintenancePlanReport(tasks: tasks),
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
              const SizedBox(height: 24),
              materialsAsync.when(
                data: (materials) => itemsAsync.when(
                  data: (items) => MaintenancePlanMaterialsSection(
                    materials: materials,
                    itemNames: {for (final item in items) item.id: item.name},
                    itemUnits: {for (final item in items) item.id: item.unit},
                  ),
                  loading: () => const AppLoading(),
                  error: (error, _) => AppErrorState(message: error.toString()),
                ),
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
              const SizedBox(height: 24),
              tasksAsync.when(
                data: (tasks) => MaintenancePlanTaskHistory(tasks: tasks),
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
            ],
          ),
        );
      },
    );
  }
}
