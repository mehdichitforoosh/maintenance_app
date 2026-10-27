import 'package:enefty_icons/enefty_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../inventory/providers/inventory_providers.dart';
import '../../providers/dashboard_providers.dart';

class DashboardContent extends ConsumerStatefulWidget {
  final String facilityId;
  final String facilityName;

  const DashboardContent({
    super.key,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  ConsumerState<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<DashboardContent> {
  int _trendDays = 7;

  @override
  Widget build(BuildContext context) {
    final facilityId = widget.facilityId;
    final summaryAsync = ref.watch(dashboardSummaryProvider(facilityId));
    final todayTasksAsync = ref.watch(dashboardTodayTasksProvider(facilityId));
    final lowStockAsync = ref.watch(lowStockItemsProvider);
    final trendRequest = (facilityId: facilityId, days: _trendDays);
    final completedTaskTrendAsync = ref.watch(
      dashboardCompletedTaskTrendProvider(trendRequest),
    );
    final materialTrendAsync = ref.watch(
      dashboardMaterialConsumptionTrendProvider(trendRequest),
    );
    final topMaterialsAsync = ref.watch(
      dashboardTopConsumedMaterialsProvider(facilityId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.facilityName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(EneftyIcons.notification_outline),
            tooltip: 'اعلان‌ها و هشدارها',
            onPressed: () => context.push('/alerts'),
          ),
          IconButton(
            icon: const Icon(EneftyIcons.setting_2_outline),
            tooltip: 'تنظیمات و مدیریت',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider(facilityId));
          ref.invalidate(dashboardTodayTasksProvider(facilityId));
          ref.invalidate(lowStockItemsProvider);
          ref.invalidate(dashboardWorkOrderStatusProvider(facilityId));
          ref.invalidate(dashboardCompletedTaskTrendProvider);
          ref.invalidate(dashboardMaterialConsumptionTrendProvider);
          ref.invalidate(dashboardTopConsumedMaterialsProvider(facilityId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Summary Cards
            summaryAsync.when(
              data: (summary) {
                final width = MediaQuery.sizeOf(context).width;
                final crossAxisCount = width >= 700 ? 4 : 2;
                final childAspectRatio = width >= 700 ? 2.0 : 1.4;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: childAspectRatio,
                  children: [
                    _SummaryCard(
                      title: 'سررسید امروز',
                      count: summary['due_today'] ?? 0,
                      color: const Color(0xFFD97706),
                      icon: EneftyIcons.calendar_2_outline,
                      onTap: () => context.push('/work-orders'),
                    ),
                    _SummaryCard(
                      title: 'معوق و تأخیر',
                      count: summary['overdue'] ?? 0,
                      color: const Color(0xFFDC2626),
                      icon: EneftyIcons.danger_outline,
                      onTap: () => context.push('/work-orders'),
                    ),
                    _SummaryCard(
                      title: 'دستورکارهای باز',
                      count: summary['open_work_orders'] ?? 0,
                      color: const Color(0xFF2563EB),
                      icon: EneftyIcons.document_text_outline,
                      onTap: () => context.push('/work-orders'),
                    ),
                    _SummaryCard(
                      title: 'اقلام کم‌موجودی',
                      count: summary['low_stock'] ?? 0,
                      color: const Color(0xFF9333EA),
                      icon: EneftyIcons.box_outline,
                      onTap: () => context.push('/inventory'),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 150, child: AppLoading()),
              error: (e, _) => Text('خطا در بارگذاری خلاصه: $e'),
            ),
            const SizedBox(height: 24),

            // Analytics Chart Report (fl_chart)
            const SectionHeader(title: 'گزارش تحلیلی وضعیت دستورکارها'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'توزيع وضعیت دستورکارها در کارگاه',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final statusAsync = ref.watch(
                            dashboardWorkOrderStatusProvider(facilityId),
                          );
                          return statusAsync.when(
                            data: (statusCounts) {
                              if (statusCounts.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'داده‌ای برای نمایش نمودار وجود ندارد.',
                                  ),
                                );
                              }
                              final openCount = statusCounts['OPEN'] ?? 0;
                              final inProgCount =
                                  statusCounts['IN_PROGRESS'] ?? 0;
                              final completedCount =
                                  statusCounts['COMPLETED'] ?? 0;
                              final cancelledCount =
                                  statusCounts['CANCELLED'] ?? 0;
                              final maxY = [
                                openCount,
                                inProgCount,
                                completedCount,
                                cancelledCount,
                              ].reduce((a, b) => a > b ? a : b).toDouble();

                              return BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxY == 0 ? 5 : maxY + 2,
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          switch (value.toInt()) {
                                            case 0:
                                              return const Text(
                                                'باز',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            case 1:
                                              return const Text(
                                                'جریان',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            case 2:
                                              return const Text(
                                                'تکمیل',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            case 3:
                                              return const Text(
                                                'لغو',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            default:
                                              return const Text('');
                                          }
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: [
                                    BarChartGroupData(
                                      x: 0,
                                      barRods: [
                                        BarChartRodData(
                                          toY: openCount.toDouble(),
                                          color: const Color(0xFF2563EB),
                                          width: 24,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 1,
                                      barRods: [
                                        BarChartRodData(
                                          toY: inProgCount.toDouble(),
                                          color: const Color(0xFFD97706),
                                          width: 24,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 2,
                                      barRods: [
                                        BarChartRodData(
                                          toY: completedCount.toDouble(),
                                          color: Colors.green,
                                          width: 24,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 3,
                                      barRods: [
                                        BarChartRodData(
                                          toY: cancelledCount.toDouble(),
                                          color: Colors.red,
                                          width: 24,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const AppLoading(),
                            error: (e, _) => Text('خطا در بارگذاری نمودار: $e'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: 'گزارش‌های عملکردی'),
            Wrap(
              spacing: 8,
              children: [
                for (final days in const [7, 30, 90])
                  ChoiceChip(
                    label: Text('${AppNumberFormat.decimal(days)} روز'),
                    selected: _trendDays == days,
                    onSelected: (_) => setState(() => _trendDays = days),
                  ),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final taskCard = _TrendCard(
                  title: 'وظایف تکمیل‌شده',
                  subtitle: '$_trendDays روز اخیر',
                  dataAsync: completedTaskTrendAsync,
                  valueKey: 'count',
                  color: const Color(0xFF10B981),
                  formatter: (value) => AppNumberFormat.decimal(value),
                );
                final materialCard = _TrendCard(
                  title: 'مصرف مواد',
                  subtitle: '$_trendDays روز اخیر',
                  dataAsync: materialTrendAsync,
                  valueKey: 'quantity',
                  color: const Color(0xFF8B5CF6),
                  formatter: (value) => AppNumberFormat.decimal(value),
                );
                if (constraints.maxWidth < 650) {
                  return Column(children: [taskCard, materialCard]);
                }
                return Row(
                  children: [
                    Expanded(child: taskCard),
                    const SizedBox(width: 12),
                    Expanded(child: materialCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: 'پرفروش‌ترین/پربازده‌ترین مواد مصرفی'),
            topMaterialsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('هیچ مصرفی برای مواد ثبت نشده است.'),
                    ),
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'] as String,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${AppNumberFormat.decimal(item['quantity'] as num)} ${item['unit']}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Text('خطا در بارگذاری مواد مصرفی: $e'),
            ),
            const SizedBox(height: 24),

            // Quick Shortcuts
            const SectionHeader(title: 'میانبرهای سریع'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ShortcutButton(
                      icon: EneftyIcons.cpu_bold,
                      label: 'تجهیز جدید',
                      onTap: () => context.push('/assets/new'),
                    ),
                    _ShortcutButton(
                      icon: EneftyIcons.document_bold,
                      label: 'دستورکار جدید',
                      onTap: () => context.push('/work-orders/new'),
                    ),
                    _ShortcutButton(
                      icon: EneftyIcons.task_bold,
                      label: 'برنامه PM',
                      onTap: () => context.push('/maintenance-plans'),
                    ),
                    _ShortcutButton(
                      icon: EneftyIcons.box_add_bold,
                      label: 'کالای انبار',
                      onTap: () => context.push('/inventory/new'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Work Tasks
            const SectionHeader(title: 'کارهای امروز'),
            todayTasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            EneftyIcons.tick_circle_bold,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'هیچ وظیفه‌ای برای امروز سررسید نشده است.',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          EneftyIcons.task_square_bold,
                          color: Color(0xFF2563EB),
                        ),
                        title: Text(
                          t['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'تجهیز: ${t['asset_name']} | کد: ${t['work_order_number']}',
                        ),
                        trailing: const Icon(EneftyIcons.arrow_left_3_outline),
                        onTap: () =>
                            context.push('/work-orders/${t['work_order_id']}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Text('خطا: $e'),
            ),
            const SizedBox(height: 24),

            // Low Stock Alert Section
            const SectionHeader(title: 'هشدار موجودی انبار'),
            lowStockAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(EneftyIcons.box_bold, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'وضعیت موجودی تمام اقلام انبار مطلوب است.',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length > 3 ? 3 : items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          EneftyIcons.danger_bold,
                          color: Color(0xFFDC2626),
                        ),
                        title: Text(
                          item['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'موجودی: ${AppNumberFormat.decimal(item['calculated_stock'] as num)} ${item['unit']} (حداقل: ${AppNumberFormat.decimal(item['minimum_stock'] as num)})',
                        ),
                        trailing: OutlinedButton.icon(
                          icon: const Icon(
                            EneftyIcons.shopping_cart_bold,
                            size: 16,
                          ),
                          label: const Text('سفارش خرید'),
                          onPressed: () => context.push('/purchases/new'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Text('خطا: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final AsyncValue<List<Map<String, dynamic>>> dataAsync;
  final String valueKey;
  final Color color;
  final String Function(double) formatter;

  const _TrendCard({
    required this.title,
    required this.subtitle,
    required this.dataAsync,
    required this.valueKey,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: dataAsync.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text('داده‌ای وجود ندارد'));
                  }

                  final maxValue = data.fold<double>(0, (prev, item) {
                    final value = (item[valueKey] as num?)?.toDouble() ?? 0;
                    return value > prev ? value : prev;
                  });

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: (data.length / 4).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= data.length ||
                                  (index != data.length - 1 &&
                                      index %
                                              (data.length / 4).ceil().clamp(
                                                1,
                                                data.length,
                                              ) !=
                                          0)) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  AppDateUtils.formatJalaliShort(
                                    data[index]['day'] as String,
                                  ),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      minY: 0,
                      maxY: maxValue == 0 ? 1 : maxValue + 1,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((spot) {
                            final index = spot.x.toInt();
                            if (index < 0 || index >= data.length) return null;
                            return LineTooltipItem(
                              '${AppDateUtils.formatJalaliShort(data[index]['day'] as String)}\n'
                              '${formatter(spot.y)}',
                              TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onInverseSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final value =
                                (item[valueKey] as num?)?.toDouble() ?? 0.0;
                            return FlSpot(index.toDouble(), value);
                          }).toList(),
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                      extraLinesData: ExtraLinesData(),
                    ),
                  );
                },
                loading: () => const Center(child: AppLoading()),
                error: (e, _) => Center(child: Text('خطا: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Text(
                    AppNumberFormat.decimal(count),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
