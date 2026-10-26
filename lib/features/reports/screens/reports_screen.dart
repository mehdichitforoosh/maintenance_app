import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_responsive_container.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/operational_report.dart';
import '../providers/report_providers.dart';
import 'widgets/report_category_sections.dart';
import 'widgets/report_bar_chart.dart';
import 'widgets/report_filter_chips.dart'
    show ReportCategoryPicker, ReportPeriodChips, ReportPeriod;

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

enum _TrendBucket { daily, weekly, monthly, quarterly }

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.week;
  ReportCategory _category = ReportCategory.workOrders;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final facilityAsync = ref.watch(primaryFacilityProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('گزارش‌های عملیاتی')),
      body: facilityAsync.when(
        data: (facility) {
          if (facility == null) {
            return const AppEmptyState(
              title: 'کارگاهی ثبت نشده است',
              message: 'برای مشاهده گزارش، ابتدا اطلاعات کارگاه را ثبت کنید.',
              icon: Icons.assessment_outlined,
            );
          }
          final range = _selectedRange;
          final reportAsync = ref.watch(
            operationalReportProvider((
              facilityId: facility.id,
              start: range.start,
              endExclusive: range.endExclusive,
            )),
          );
          return AppResponsiveContainer(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
              Text(
                'بازه گزارش',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              _periodControls(context),
              const SizedBox(height: 4),
              _dateRangeLabel(context, range),
              const SizedBox(height: 14),
              Text(
                'دسته گزارش',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ReportCategoryPicker(
                selected: _category,
                onSelected: (category) => setState(() => _category = category),
              ),
              const SizedBox(height: 12),
              reportAsync.when(
                data: (report) => ReportCategorySections(
                  category: _category,
                  report: report,
                  taskTrend: _trendValues(
                    report.taskTrend,
                    range.start,
                    range.endExclusive,
                    (point) => point.taskCount.toDouble(),
                  ),
                  receiptTrend: _trendValues(
                    report.receiptTrend,
                    range.start,
                    range.endExclusive,
                    (point) => point.receivedCost,
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: AppLoading(),
                ),
                error: (error, _) => AppErrorState(message: error.toString()),
              ),
            ],
          ),
          );
        },
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(message: error.toString()),
      ),
    );
  }

  Widget _periodControls(BuildContext context) {
    return ReportPeriodChips(
      selected: _period,
      onSelected: (selected) {
        if (selected == ReportPeriod.custom) {
          _selectCustomRange();
        } else {
          setState(() => _period = selected);
        }
      },
    );
  }

  Widget _dateRangeLabel(BuildContext context, _DateRange range) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${AppDateUtils.formatJalali(range.start.toIso8601String())}'
            ' تا ${AppDateUtils.formatJalali(range.endExclusive.subtract(const Duration(days: 1)).toIso8601String())}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _selectCustomRange,
          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
          label: const Text('تغییر'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(2000);
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
      helpText: 'انتخاب بازه گزارش',
      saveText: 'تأیید',
    );
    if (selectedRange == null || !mounted) return;
    setState(() {
      _customStart = DateTime(
        selectedRange.start.year,
        selectedRange.start.month,
        selectedRange.start.day,
      );
      _customEnd = DateTime(
        selectedRange.end.year,
        selectedRange.end.month,
        selectedRange.end.day,
      );
      _period = ReportPeriod.custom;
    });
  }

  _DateRange get _selectedRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case ReportPeriod.week:
        final daysSinceSaturday = (today.weekday + 1) % 7;
        final start = today.subtract(Duration(days: daysSinceSaturday));
        return _DateRange(start, today.add(const Duration(days: 1)));
      case ReportPeriod.month:
        final jalaliToday = Jalali.fromDateTime(today);
        return _DateRange(
          Jalali(jalaliToday.year, jalaliToday.month, 1).toDateTime(),
          today.add(const Duration(days: 1)),
        );
      case ReportPeriod.year:
        final jalaliToday = Jalali.fromDateTime(today);
        return _DateRange(
          Jalali(jalaliToday.year, 1, 1).toDateTime(),
          today.add(const Duration(days: 1)),
        );
      case ReportPeriod.custom:
        final start = _customStart ?? today;
        final end = _customEnd ?? today;
        return _DateRange(start, end.add(const Duration(days: 1)));
    }
  }

  List<ReportChartValue> _trendValues(
    List<ReportTrendPoint> points,
    DateTime start,
    DateTime endExclusive,
    double Function(ReportTrendPoint) valueOf,
  ) {
    final spanDays = endExclusive.difference(start).inDays;
    final bucketType = spanDays <= 14
        ? _TrendBucket.daily
        : spanDays <= 45
        ? _TrendBucket.weekly
        : spanDays <= 366
        ? _TrendBucket.monthly
        : _TrendBucket.quarterly;
    final bucketCount = _bucketCount(bucketType, start, endExclusive, spanDays);
    final totals = List<double>.filled(bucketCount, 0);
    for (final point in points) {
      final date = DateTime.tryParse(point.date);
      if (date == null) continue;
      final dayOffset = DateTime(
        date.year,
        date.month,
        date.day,
      ).difference(start).inDays;
      if (dayOffset < 0 || dayOffset >= spanDays) continue;
      final jalaliDate = Jalali.fromDateTime(date);
      final jalaliStart = Jalali.fromDateTime(start);
      final monthOffset =
          (jalaliDate.year - jalaliStart.year) * 12 +
          jalaliDate.month -
          jalaliStart.month;
      final index = switch (bucketType) {
        _TrendBucket.daily => dayOffset,
        _TrendBucket.weekly => dayOffset ~/ 7,
        _TrendBucket.monthly => monthOffset,
        _TrendBucket.quarterly => monthOffset ~/ 3,
      };
      if (index < 0 || index >= bucketCount) continue;
      totals[index] += valueOf(point);
    }
    return List.generate(bucketCount, (index) {
      final date = switch (bucketType) {
        _TrendBucket.daily => start.add(Duration(days: index)),
        _TrendBucket.weekly => start.add(Duration(days: index * 7)),
        _TrendBucket.monthly => _jalaliMonthStart(start, index),
        _TrendBucket.quarterly => _jalaliMonthStart(start, index * 3),
      };
      return ReportChartValue(
        AppDateUtils.formatJalaliShort(date.toIso8601String()),
        totals[index],
      );
    });
  }

  int _bucketCount(
    _TrendBucket type,
    DateTime start,
    DateTime endExclusive,
    int spanDays,
  ) {
    if (type == _TrendBucket.daily) return spanDays;
    if (type == _TrendBucket.weekly) return (spanDays / 7).ceil();

    final firstMonth = Jalali.fromDateTime(start);
    final lastMonth = Jalali.fromDateTime(
      endExclusive.subtract(const Duration(microseconds: 1)),
    );
    final monthCount =
        (lastMonth.year - firstMonth.year) * 12 +
        lastMonth.month -
        firstMonth.month +
        1;
    return type == _TrendBucket.monthly ? monthCount : (monthCount / 3).ceil();
  }

  DateTime _jalaliMonthStart(DateTime start, int monthOffset) {
    final jalali = Jalali.fromDateTime(start);
    var year = jalali.year;
    var month = jalali.month + monthOffset;
    while (month > 12) {
      month -= 12;
      year++;
    }
    return Jalali(year, month, 1).toDateTime();
  }
}

class _DateRange {
  final DateTime start;
  final DateTime endExclusive;

  const _DateRange(this.start, this.endExclusive);
}
