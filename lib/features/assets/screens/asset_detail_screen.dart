import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../maintenance/providers/maintenance_providers.dart';
import '../providers/asset_providers.dart';

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
        if (asset == null) return const Scaffold(body: Center(child: Text('تجهیز یافت نشد')));

        return Scaffold(
          appBar: AppBar(
            title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('مشخصات تجهیز', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(asset.status.displayName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _infoRow('کد تجهیز', asset.code),
                      _infoRow('نوع', asset.assetType.displayName),
                      if (asset.manufacturer != null && asset.manufacturer!.isNotEmpty) _infoRow('سازنده', asset.manufacturer!),
                      if (asset.model != null && asset.model!.isNotEmpty) _infoRow('مدل', asset.model!),
                      if (asset.serialNumber != null && asset.serialNumber!.isNotEmpty) _infoRow('شماره سریال', asset.serialNumber!),
                      if (asset.description != null && asset.description!.isNotEmpty) _infoRow('توضیحات', asset.description!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/assets/$assetId/readings'),
                      icon: const Icon(EneftyIcons.graph_bold, size: 18),
                      label: const Text('خوانش‌های تجهیز'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/maintenance-plans/new?assetId=$assetId'),
                      icon: const Icon(EneftyIcons.add_bold, size: 18),
                      label: const Text('برنامه PM جدید'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'برنامه‌های نگهداری (PM)'),
              plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) return const Text('برنامه نگهداری ثبت نشده است.');
                  return Column(
                    children: plans.map((p) => Card(
                      child: ListTile(
                        leading: const Icon(EneftyIcons.calendar_2_bold, color: Colors.blue),
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('نوع زمان‌بندی: ${p.scheduleType.displayName} | اولویت: ${p.priority.displayName}'),
                        trailing: const Icon(EneftyIcons.arrow_left_3_outline, size: 18),
                        onTap: () => context.push('/maintenance-plans/${p.id}/edit'),
                      ),
                    )).toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('خطا: $e'),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'آخرین خوانش‌های تجهیز'),
              readingsAsync.when(
                data: (readings) {
                  if (readings.isEmpty) return const Text('خوانشی ثبت نشده است.');
                  return Column(
                    children: readings.take(5).map((r) => Card(
                      child: ListTile(
                        leading: const Icon(EneftyIcons.graph_bold, color: Colors.teal),
                        title: Text('${r.metricName}: ${r.value} ${r.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('تاریخ: ${r.recordedAt}'),
                      ),
                    )).toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('خطa: $e'),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
