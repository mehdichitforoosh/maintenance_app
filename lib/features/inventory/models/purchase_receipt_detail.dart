class PurchaseReceiptDetail {
  final String transactionId;
  final String itemId;
  final String itemName;
  final String itemCode;
  final String unit;
  final double quantity;
  final double? unitCost;
  final String transactionDate;
  final String? notes;
  final String purchaseOrderId;
  final String purchaseOrderNumber;
  final String? supplierName;

  const PurchaseReceiptDetail({
    required this.transactionId,
    required this.itemId,
    required this.itemName,
    required this.itemCode,
    required this.unit,
    required this.quantity,
    this.unitCost,
    required this.transactionDate,
    this.notes,
    required this.purchaseOrderId,
    required this.purchaseOrderNumber,
    this.supplierName,
  });

  factory PurchaseReceiptDetail.fromMap(Map<String, Object?> map) {
    return PurchaseReceiptDetail(
      transactionId: map['transaction_id'] as String,
      itemId: map['item_id'] as String,
      itemName: map['item_name'] as String,
      itemCode: map['item_code'] as String,
      unit: map['unit'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      transactionDate: map['transaction_date'] as String,
      notes: map['notes'] as String?,
      purchaseOrderId: map['purchase_order_id'] as String,
      purchaseOrderNumber: map['purchase_order_number'] as String,
      supplierName: map['supplier_name'] as String?,
    );
  }
}
