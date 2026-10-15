import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/number_format_utils.dart';

class InventoryCurrentStockGauge extends StatelessWidget {
  final double stock;
  final double minimumStock;
  final String unit;

  const InventoryCurrentStockGauge({
    super.key,
    required this.stock,
    required this.minimumStock,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLow = minimumStock > 0 && stock <= minimumStock;
    final gaugeLimit = minimumStock > 0 ? minimumStock : stock;
    final progress = gaugeLimit <= 0
        ? 0.0
        : (stock / gaugeLimit).clamp(0.0, 1.0);
    final gaugeColor = isLow ? colors.error : Colors.green;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'موجودی فعلی',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: 3.141592653589793,
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: 180,
                        centerSpaceRadius: 54,
                        sectionsSpace: 0,
                        pieTouchData: PieTouchData(enabled: false),
                        sections: [
                          PieChartSectionData(
                            value: (progress * 180).clamp(0.01, 180),
                            color: gaugeColor,
                            radius: 17,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (180 - progress * 180).clamp(0.01, 180),
                            color: colors.surfaceContainerHighest,
                            radius: 17,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 180,
                            color: Colors.transparent,
                            radius: 17,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 38,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppNumberFormat.decimal(stock),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          unit,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('۰', style: TextStyle(color: colors.onSurfaceVariant)),
                Text(
                  minimumStock > 0
                      ? 'حداقل: ${AppNumberFormat.decimal(minimumStock)} $unit'
                      : 'حداقل موجودی تعریف نشده',
                  style: TextStyle(
                    color: isLow ? colors.error : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
