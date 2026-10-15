import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../models/operational_report.dart';
import 'report_bar_chart.dart';
import 'report_summary_widgets.dart';

enum ReportCategory { workOrders, materials, purchases }

class ReportCategorySections extends StatelessWidget {
  final ReportCategory category;
  final OperationalReport report;
  final List<ReportChartValue> taskTrend;
  final List<ReportChartValue> receiptTrend;

  const ReportCategorySections({
    super.key,
    required this.category,
    required this.report,
    required this.taskTrend,
    required this.receiptTrend,
  });

  @override
  Widget build(BuildContext context) {
    return switch (category) {
      ReportCategory.workOrders => _workOrderReport(context),
      ReportCategory.materials => _materialsReport(context),
      ReportCategory.purchases => _purchasesReport(context),
    };
  }

  Widget _workOrderReport(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportMetricCards(
          values: [
            ReportMetric(
              'وظایف تکمیل‌شده',
              AppNumberFormat.decimal(report.completedTasks),
              Icons.task_alt_outlined,
            ),
            ReportMetric(
              'زمان کار',
              _formatHours(report.laborMinutes),
              Icons.handyman_outlined,
            ),
            ReportMetric(
              'زمان توقف',
              _formatHours(report.downtimeMinutes),
              Icons.pause_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReportBarChart(
          title: 'روند تکمیل وظایف',
          valueLabel: 'وظیفه',
          values: taskTrend,
        ),
        const SizedBox(height: 12),
        const ReportTableHeading(
          title: 'وظایف تکمیل‌شده',
          subtitle: '۵۰ مورد آخر',
        ),
        if (report.completedTaskRows.isEmpty)
          const NoReportData(message: 'در این بازه وظیفه‌ای تکمیل نشده است.')
        else
          ReportTableCard(
            columns: const ['وظیفه / تجهیز / تاریخ', 'شماره کار', 'زمان کار'],
            rows: report.completedTaskRows
                .map(
                  (task) => [
                    '${task.title}\n${task.assetName}\n'
                        '${AppDateUtils.formatJalaliShort(task.completedAt)}',
                    task.workOrderNumber,
                    _formatHours(task.laborMinutes),
                  ],
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _materialsReport(BuildContext context) {
    final costValues =
        report.materialUsage
            .where((usage) => usage.totalCost > 0)
            .take(8)
            .map((usage) => ReportChartValue(usage.name, usage.totalCost))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportMetricCards(
          values: [
            ReportMetric(
              'تراکنش مصرف',
              AppNumberFormat.decimal(report.consumedTransactionCount),
              Icons.swap_horiz_outlined,
            ),
            ReportMetric(
              'هزینه ثبت‌شده',
              AppNumberFormat.decimal(report.consumedCost),
              Icons.payments_outlined,
            ),
            ReportMetric(
              'اقلام مصرف‌شده',
              AppNumberFormat.decimal(report.consumedItemCount),
              Icons.inventory_2_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReportBarChart(
          title: 'بیشترین هزینه مصرف قطعات',
          valueLabel: 'هزینه',
          values: costValues,
        ),
        if (report.unpricedConsumptionCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'هزینه ${AppNumberFormat.decimal(report.unpricedConsumptionCount)} تراکنش مصرف ثبت نشده و در جمع هزینه لحاظ نشده است.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 12),
        const ReportTableHeading(
          title: 'مصرف به تفکیک کالا',
          subtitle: '۲۰ قلم اول',
        ),
        if (report.materialUsage.isEmpty)
          const NoReportData(message: 'در این بازه مصرفی ثبت نشده است.')
        else
          ReportTableCard(
            columns: const ['کالا', 'مقدار', 'هزینه ثبت‌شده'],
            rows: report.materialUsage
                .map(
                  (usage) => [
                    usage.name,
                    '${AppNumberFormat.decimal(usage.quantity)} ${usage.unit}',
                    usage.hasUnpricedCost
                        ? 'نامشخص'
                        : AppNumberFormat.decimal(usage.totalCost),
                  ],
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _purchasesReport(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportMetricCards(
          values: [
            ReportMetric(
              'ردیف‌های رسید',
              AppNumberFormat.decimal(report.receiptCount),
              Icons.receipt_long_outlined,
            ),
            ReportMetric(
              'ارزش دریافت‌شده',
              AppNumberFormat.decimal(report.receivedCost),
              Icons.payments_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReportBarChart(
          title: 'ارزش دریافت کالا در بازه',
          valueLabel: 'هزینه',
          values: receiptTrend,
        ),
        const SizedBox(height: 12),
        const ReportTableHeading(
          title: 'ریز رسیدهای خرید',
          subtitle: '۱۰۰ مورد آخر',
        ),
        if (report.receipts.isEmpty)
          const NoReportData(message: 'در این بازه رسید خریدی ثبت نشده است.')
        else
          ReportTableCard(
            columns: const ['سفارش / کالا', 'مقدار', 'ارزش', 'تاریخ'],
            rows: report.receipts
                .map(
                  (receipt) => [
                    '${receipt.purchaseOrderNumber}\n'
                        '${receipt.supplierName ?? 'بدون نام تأمین‌کننده'}\n'
                        '${receipt.itemName}',
                    '${AppNumberFormat.decimal(receipt.quantity)} ${receipt.unit}',
                    AppNumberFormat.decimal(receipt.totalCost),
                    AppDateUtils.formatJalaliShort(receipt.transactionDate),
                  ],
                )
                .toList(),
          ),
      ],
    );
  }

  String _formatHours(int minutes) {
    return '${AppNumberFormat.decimal(minutes / 60)} ساعت';
  }
}
