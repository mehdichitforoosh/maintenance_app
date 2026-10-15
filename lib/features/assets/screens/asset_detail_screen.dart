import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../maintenance/providers/maintenance_providers.dart';
import '../providers/asset_providers.dart';
import 'widgets/asset_detail_sections.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(assetDetailProvider(assetId));
    final readingsAsync = ref.watch(assetReadingsProvider(assetId));
    final plansAsync = ref.watch(maintenancePlansProvider(assetId));

    return assetAsync.when(
      data: (asset) {
        if (asset == null) {
          return const Scaffold(body: Center(child: Text('تجهیز یافت نشد')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              asset.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(EneftyIcons.edit_2_outline),
                tooltip: 'ویرایش تجهیز',
                onPressed: () => context.push('/assets/$assetId/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AssetSpecificationsCard(asset: asset),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/assets/$assetId/readings'),
                      icon: const Icon(
                        EneftyIcons.speedometer_outline,
                        size: 18,
                      ),
                      label: const Text('خوانش‌های تجهیز'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        '/maintenance-plans/new?assetId=$assetId',
                      ),
                      icon: const Icon(
                        EneftyIcons.add_square_outline,
                        size: 18,
                      ),
                      label: const Text('برنامه PM جدید'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              plansAsync.when(
                data: (plans) => AssetMaintenancePlansSection(
                  plans: plans,
                  onPlanTap: (plan) =>
                      context.push('/maintenance-plans/${plan.id}/edit'),
                ),
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
              const SizedBox(height: 24),
              readingsAsync.when(
                data: (readings) =>
                    AssetRecentReadingsSection(readings: readings),
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (error, _) =>
          Scaffold(body: AppErrorState(message: error.toString())),
    );
  }
}
