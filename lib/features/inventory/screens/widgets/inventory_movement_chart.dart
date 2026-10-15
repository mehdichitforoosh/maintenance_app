import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/enums/app_enums.dart';
import '../../models/stock_transaction.dart';

class InventoryMovementChart extends StatefulWidget {
  final List<StockTransaction> transactions;
  final String unit;

  const InventoryMovementChart({
    super.key,
    required this.transactions,
    required this.unit,
  });

  @override
  State<InventoryMovementChart> createState() => _InventoryMovementChartState();
}

class _InventoryMovementChartState extends State<InventoryMovementChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final incoming = widget.transactions
        .where(_isIncoming)
        .fold<double>(0, (sum, transaction) => sum + transaction.quantity);
    final outgoing = widget.transactions
        .where((transaction) => !_isIncoming(transaction))
        .fold<double>(0, (sum, transaction) => sum + transaction.quantity);
    if (incoming == 0 && outgoing == 0) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final values = [incoming, outgoing];
    final labels = ['ورودی', 'خروجی'];
    final swatches = [Colors.green, colors.error];
    final visibleIndices = [
      for (var index = 0; index < values.length; index++)
        if (values[index] > 0) index,
    ];
    final selected = _selectedIndex;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'گردش ورودی و خروجی',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 38,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions) return;
                            final touched =
                                response?.touchedSection?.touchedSectionIndex;
                            setState(() {
                              _selectedIndex =
                                  touched != null &&
                                      touched >= 0 &&
                                      touched < visibleIndices.length
                                  ? visibleIndices[touched]
                                  : null;
                            });
                          },
                        ),
                        sections: visibleIndices
                            .map(
                              (index) => PieChartSectionData(
                                value: values[index],
                                color: swatches[index],
                                radius: selected == index ? 24 : 20,
                                showTitle: false,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: selected == null
                          ? Text(
                              'ورودی و خروجی\n${widget.unit}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  labels[selected],
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: swatches[selected],
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${values[selected]} ${widget.unit}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _MovementLegend(
                  label: 'ورودی',
                  amount: incoming,
                  unit: widget.unit,
                  color: swatches[0],
                ),
                _MovementLegend(
                  label: 'خروجی',
                  amount: outgoing,
                  unit: widget.unit,
                  color: swatches[1],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isIncoming(StockTransaction transaction) {
    return switch (transaction.transactionType) {
      TransactionType.purchaseReceipt ||
      TransactionType.adjustmentIn ||
      TransactionType.returnItem => true,
      TransactionType.maintenanceConsumption ||
      TransactionType.adjustmentOut => false,
    };
  }
}

class _MovementLegend extends StatelessWidget {
  final String label;
  final double amount;
  final String unit;
  final Color color;

  const _MovementLegend({
    required this.label,
    required this.amount,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text('$label: $amount $unit'),
      ],
    );
  }
}
