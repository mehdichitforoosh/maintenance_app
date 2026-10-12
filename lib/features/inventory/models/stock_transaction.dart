import '../../../core/enums/app_enums.dart';

class StockTransaction {
  final String id;
  final String itemId;
  final TransactionType transactionType;
  final double quantity;
  final double? unitCost;
  final String transactionDate;
  final String? purchaseOrderItemId;
  final String? workOrderMaterialId;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const StockTransaction({
    required this.id,
    required this.itemId,
    required this.transactionType,
    required this.quantity,
    this.unitCost,
    required this.transactionDate,
    this.purchaseOrderItemId,
    this.workOrderMaterialId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'transaction_type': transactionType.toDbString(),
      'quantity': quantity,
      'unit_cost': unitCost,
      'transaction_date': transactionDate,
      'purchase_order_item_id': purchaseOrderItemId,
      'work_order_material_id': workOrderMaterialId,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      transactionType: TransactionType.fromDbString(map['transaction_type'] as String?),
      quantity: (map['quantity'] as num).toDouble(),
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      transactionDate: map['transaction_date'] as String,
      purchaseOrderItemId: map['purchase_order_item_id'] as String?,
      workOrderMaterialId: map['work_order_material_id'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
