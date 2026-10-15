import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../maintenance/models/maintenance_plan.dart';
import '../../models/asset.dart';
import '../../models/asset_reading.dart';
import 'asset_reading_tile.dart';

class AssetSpecificationsCard extends StatelessWidget {
  final Asset asset;

  const AssetSpecificationsCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (asset.status) {
      AssetStatus.active => Colors.green,
      AssetStatus.underMaintenance => Colors.orange,
      AssetStatus.inactive => Colors.grey,
      AssetStatus.retired => Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مشخصات تجهیز',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    asset.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 20),
            _infoRow(context, 'کد تجهیز', asset.code),
            _infoRow(context, 'نوع', asset.assetType.displayName),
            if (_hasText(asset.manufacturer))
              _infoRow(context, 'سازنده', asset.manufacturer!),
            if (_hasText(asset.model)) _infoRow(context, 'مدل', asset.model!),
            if (_hasText(asset.serialNumber))
              _infoRow(context, 'شماره سریال', asset.serialNumber!),
            if (_hasText(asset.installationDate))
              _infoRow(
                context,
                'تاریخ نصب',
                AppDateUtils.formatJalali(asset.installationDate),
              ),
            if (_hasText(asset.commissioningDate))
              _infoRow(
                context,
                'تاریخ بهره‌برداری',
                AppDateUtils.formatJalali(asset.commissioningDate),
              ),
            if (_hasText(asset.description))
              _infoRow(context, 'توضیحات', asset.description!),
          ],
        ),
      ),
    );
  }

  static bool _hasText(String? value) => value != null && value.isNotEmpty;

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
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

class AssetMaintenancePlansSection extends StatelessWidget {
  final List<MaintenancePlan> plans;
  final ValueChanged<MaintenancePlan> onPlanTap;

  const AssetMaintenancePlansSection({
    super.key,
    required this.plans,
    required this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'برنامه‌های نگهداری (PM)'),
        if (plans.isEmpty)
          const Text('برنامه نگهداری ثبت نشده است.')
        else
          ...plans.map((plan) {
            final color = AppColors.priorityColor(plan.priority);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: const Icon(EneftyIcons.calendar_2_outline),
                ),
                title: Text(
                  plan.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'نوع زمان‌بندی: ${plan.scheduleType.displayName}',
                ),
                trailing: Chip(
                  label: Text(
                    plan.priority.displayName,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: color.withValues(alpha: 0.12),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => onPlanTap(plan),
              ),
            );
          }),
      ],
    );
  }
}

class AssetRecentReadingsSection extends StatelessWidget {
  final List<AssetReading> readings;

  const AssetRecentReadingsSection({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'آخرین خوانش‌های تجهیز'),
        if (readings.isEmpty)
          const Text('خوانشی ثبت نشده است.')
        else
          ...readings
              .take(5)
              .map((reading) => AssetReadingTile(reading: reading)),
      ],
    );
  }
}
