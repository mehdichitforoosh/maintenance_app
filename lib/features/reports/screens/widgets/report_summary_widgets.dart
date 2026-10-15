import 'package:flutter/material.dart';

class ReportMetric {
  final String title;
  final String value;
  final IconData icon;

  const ReportMetric(this.title, this.value, this.icon);
}

class ReportMetricCards extends StatelessWidget {
  final List<ReportMetric> values;

  const ReportMetricCards({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            metric.icon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metric.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  metric.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class ReportTableHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const ReportTableHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class ReportTableCard extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const ReportTableCard({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          columns: columns
              .map((column) => DataColumn(label: Text(column)))
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row.map((value) => DataCell(Text(value))).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class NoReportData extends StatelessWidget {
  final String message;

  const NoReportData({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.insert_chart_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
