class OperationalReport {
  final int completedTasks;
  final int laborMinutes;
  final int downtimeMinutes;
  final List<ReportTrendPoint> taskTrend;
  final List<ReportCompletedTask> completedTaskRows;
  final int consumedTransactionCount;
  final int consumedItemCount;
  final int unpricedConsumptionCount;
  final double totalConsumedCost;
  final List<ReportMaterialUsage> materialUsage;
  final int receivedTransactionCount;
  final double totalReceivedCost;
  final List<ReportTrendPoint> receiptTrend;
  final List<ReportReceipt> receipts;

  const OperationalReport({
    required this.completedTasks,
    required this.laborMinutes,
    required this.downtimeMinutes,
    required this.taskTrend,
    required this.completedTaskRows,
    required this.consumedTransactionCount,
    required this.consumedItemCount,
    required this.unpricedConsumptionCount,
    required this.totalConsumedCost,
    required this.materialUsage,
    required this.receivedTransactionCount,
    required this.totalReceivedCost,
    required this.receiptTrend,
    required this.receipts,
  });

  double get consumedCost => totalConsumedCost;

  int get receiptCount => receivedTransactionCount;

  double get receivedCost => totalReceivedCost;
}

class ReportTrendPoint {
  final String date;
  final int taskCount;
  final double laborHours;
  final double downtimeHours;
  final double receivedCost;

  const ReportTrendPoint({
    required this.date,
    this.taskCount = 0,
    this.laborHours = 0,
    this.downtimeHours = 0,
    this.receivedCost = 0,
  });
}

class ReportCompletedTask {
  final String title;
  final String assetName;
  final String workOrderNumber;
  final String completedAt;
  final int laborMinutes;
  final int downtimeMinutes;

  const ReportCompletedTask({
    required this.title,
    required this.assetName,
    required this.workOrderNumber,
    required this.completedAt,
    required this.laborMinutes,
    required this.downtimeMinutes,
  });
}

class ReportMaterialUsage {
  final String name;
  final String unit;
  final double quantity;
  final double totalCost;
  final bool hasUnpricedCost;

  const ReportMaterialUsage({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.totalCost,
    required this.hasUnpricedCost,
  });
}

class ReportReceipt {
  final String purchaseOrderNumber;
  final String? supplierName;
  final String itemName;
  final String unit;
  final double quantity;
  final double unitCost;
  final String transactionDate;

  const ReportReceipt({
    required this.purchaseOrderNumber,
    required this.supplierName,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitCost,
    required this.transactionDate,
  });

  double get totalCost => quantity * unitCost;
}
