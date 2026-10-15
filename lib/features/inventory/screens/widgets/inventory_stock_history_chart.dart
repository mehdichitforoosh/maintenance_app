import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/stock_transaction.dart';

class InventoryStockHistoryChart extends StatelessWidget {
  final List<StockTransaction> transactions;
  final double minimumStock;
  final String unit;

  const InventoryStockHistoryChart({
    super.key,
    required this.transactions,
    required this.minimumStock,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final points = _buildBalancePoints();
    final colors = Theme.of(context).colorScheme;
    final values = points.map((point) => point.balance).toList()
      ..add(minimumStock);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final padding = range == 0 ? 1.0 : range * 0.15;
    final minY = minValue < 0 ? minValue - padding : 0.0;
    final maxY = maxValue + padding;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'روند موجودی',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'برای دیدن تاریخ و مقدار، نمودار را لمس کنید.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  minX: -0.55,
                  maxX: points.length == 1
                      ? 0.55
                      : points.length.toDouble() - 0.45,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.outlineVariant.withValues(alpha: 0.45),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _titles(context, points),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final point = points[spot.spotIndex];
                        return LineTooltipItem(
                          '${AppDateUtils.formatJalali(point.transaction.transactionDate)}\n'
                          '${point.balance} $unit',
                          TextStyle(
                            color: colors.onInverseSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: minimumStock,
                        color: colors.error,
                        strokeWidth: 1.5,
                        dashArray: [5, 4],
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points
                          .asMap()
                          .entries
                          .map(
                            (entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.balance,
                            ),
                          )
                          .toList(),
                      isCurved: false,
                      color: colors.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: points.length <= 12),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendItem(label: 'موجودی', color: colors.primary),
                _LegendItem(label: 'حداقل موجودی', color: colors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_StockBalancePoint> _buildBalancePoints() {
    final ordered = transactions.toList()
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    var balance = 0.0;
    return ordered.map((transaction) {
      balance += switch (transaction.transactionType) {
        TransactionType.purchaseReceipt ||
        TransactionType.adjustmentIn ||
        TransactionType.returnItem => transaction.quantity,
        TransactionType.maintenanceConsumption ||
        TransactionType.adjustmentOut => -transaction.quantity,
      };
      return _StockBalancePoint(transaction: transaction, balance: balance);
    }).toList();
  }

  FlTitlesData _titles(BuildContext context, List<_StockBalancePoint> points) {
    final colors = Theme.of(context).colorScheme;
    final interval = ((points.length - 1) / 3).ceilToDouble();
    final labelInterval = interval < 1 ? 1 : interval.toInt();
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: labelInterval.toDouble(),
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 ||
                index >= points.length ||
                (value - index).abs() > 0.01 ||
                (index % labelInterval != 0 && index != points.length - 1)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              space: 2,
              fitInside: SideTitleFitInsideData.fromTitleMeta(
                meta,
                distanceFromEdge: 2,
              ),
              child: SizedBox(
                width: 42,
                child: Text(
                  AppDateUtils.formatJalaliShort(
                    points[index].transaction.transactionDate,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StockBalancePoint {
  final StockTransaction transaction;
  final double balance;

  const _StockBalancePoint({required this.transaction, required this.balance});
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 2, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
