import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/jalali_extensions.dart';
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

        final statusColor = switch (asset.status.name) {
          'active' || 'ACTIVE' => Colors.green,
          'underMaintenance' || 'UNDER_MAINTENANCE' => Colors.orange,
          'inactive' || 'INACTIVE' => Colors.grey,
          'retired' || 'RETIRED' => Colors.red,
          _ => Theme.of(context).colorScheme.primary,
        };

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
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(asset.status.displayName, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _infoRow('کد تجهیز', asset.code),
                      _infoRow('نوع', asset.assetType.displayName),
                      if (asset.manufacturer != null && asset.manufacturer!.isNotEmpty) _infoRow('سازنده', asset.manufacturer!),
                      if (asset.model != null && asset.model!.isNotEmpty) _infoRow('مدل', asset.model!),
                      if (asset.serialNumber != null && asset.serialNumber!.isNotEmpty) _infoRow('شماره سریال', asset.serialNumber!),
                      if (asset.installationDate != null && asset.installationDate!.isNotEmpty) _infoRow('تاریخ نصب', _formatPersianDate(asset.installationDate!)),
                      if (asset.commissioningDate != null && asset.commissioningDate!.isNotEmpty) _infoRow('تاریخ بهره‌برداری', _formatPersianDate(asset.commissioningDate!)),
                      if (asset.description != null && asset.description!.isNotEmpty) _infoRow('توضیحات', asset.description!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/assets/$assetId/readings'),
                      icon: const Icon(EneftyIcons.speedometer_outline, size: 18),
                      label: const Text('خوانش‌های تجهیز'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/maintenance-plans/new?assetId=$assetId'),
                      icon: const Icon(EneftyIcons.add_square_outline, size: 18),
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
                    children: plans.map((p) {
                      final priorityColor = AppColors.priorityColor(p.priority);

                      return Card(
                        child: ListTile(
                          leading: const Icon(EneftyIcons.calendar_2_outline, color: Colors.blue),
                          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('نوع زمان‌بندی: ${p.scheduleType.displayName}'),
                          trailing: Chip(
                            label: Text('اولویت: ${p.priority.displayName}', style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            backgroundColor: priorityColor.withValues(alpha: 0.12),
                            side: BorderSide(color: priorityColor.withValues(alpha: 0.35)),
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () => context.push('/maintenance-plans/${p.id}/edit'),
                        ),
                      );
                    }).toList(),
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
                        leading: const Icon(EneftyIcons.speedometer_bold, color: Colors.teal),
                        title: Text('${r.metricName}: ${r.value} ${r.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('تاریخ: ${_formatPersianDate(r.recordedAt)}'),
                      ),
                    )).toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('خطا: $e'),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }


  String _formatPersianDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return parsed.toShamsiDate();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
