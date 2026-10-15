import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../providers/asset_providers.dart';
import 'widgets/asset_reading_trend_chart.dart';
import 'widgets/asset_reading_tile.dart';

class AssetMeterTrendScreen extends ConsumerWidget {
  final String assetId;
  final String metricName;
  final String unit;

  const AssetMeterTrendScreen({
    super.key,
    required this.assetId,
    required this.metricName,
    required this.unit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (metricName.trim().isEmpty || unit.trim().isEmpty) {
      return const Scaffold(
        body: AppErrorState(message: 'شاخص یا واحد اندازه‌گیری نامعتبر است.'),
      );
    }

    final readingsAsync = ref.watch(assetReadingsProvider(assetId));
    return Scaffold(
      appBar: AppBar(title: Text('${_displayName(metricName)} ($unit)')),
      body: readingsAsync.when(
        data: (readings) {
          final meterReadings =
              readings
                  .where(
                    (reading) =>
                        reading.metricName == metricName &&
                        reading.unit == unit,
                  )
                  .toList()
                ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
          if (meterReadings.isEmpty) {
            return const AppEmptyState(
              title: 'خوانشی برای این شاخص وجود ندارد',
              message: 'برای نمایش روند، ابتدا یک خوانش ثبت کنید.',
              icon: Icons.speed_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AssetReadingTrendChart(readings: meterReadings),
              const SizedBox(height: 20),
              Text(
                'تاریخچه خوانش‌ها',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...meterReadings.map(
                (reading) => AssetReadingTile(reading: reading),
              ),
            ],
          );
        },
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(message: error.toString()),
      ),
    );
  }

  String _displayName(String metric) {
    return switch (metric) {
      'operating_hours' => 'ساعت کارکرد',
      'temperature' => 'دما',
      'pressure' => 'فشار',
      'vibration' => 'لرزش',
      _ => metric.replaceAll('_', ' '),
    };
  }
}
