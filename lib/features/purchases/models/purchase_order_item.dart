class PurchaseOrderItem {
  final String id;
  final String purchaseOrderId;
  final String itemId;
  final double orderedQuantity;
  final double unitPrice;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.itemId,
    required this.orderedQuantity,
    required this.unitPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'item_id': itemId,
      'ordered_quantity': orderedQuantity,
      'unit_price': unitPrice,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'] as String,
      purchaseOrderId: map['purchase_order_id'] as String,
      itemId: map['item_id'] as String,
      orderedQuantity: (map['ordered_quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
