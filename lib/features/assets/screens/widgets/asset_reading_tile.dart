import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../models/asset_reading.dart';

class AssetReadingTile extends StatelessWidget {
  final AssetReading reading;
  final VoidCallback? onEdit;

  const AssetReadingTile({super.key, required this.reading, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = reading.notes?.trim();
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.monitor_heart_outlined),
        ),
        title: Text(
          _metricDisplayName(reading.metricName),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppNumberFormat.decimal(reading.value)} ${reading.unit}',
                style: valueStyle,
              ),
              const SizedBox(height: 3),
              Text(
                AppDateUtils.formatDisplay(reading.recordedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(notes),
              ],
              if (reading.supersededByReadingId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'اصلاح‌شده: ${reading.correctionReason ?? 'دلیل ثبت نشده'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: onEdit != null && reading.supersededByReadingId == null
            ? IconButton(
                tooltip: 'اصلاح خوانش',
                onPressed: onEdit,
                icon: const Icon(EneftyIcons.edit_2_outline),
              )
            : null,
      ),
    );
  }

  static String _metricDisplayName(String metricName) {
    return switch (metricName) {
      'operating_hours' => 'ساعت کارکرد',
      'temperature' => 'دما',
      'pressure' => 'فشار',
      'vibration' => 'لرزش',
      _ => metricName.replaceAll('_', ' '),
    };
  }
}
