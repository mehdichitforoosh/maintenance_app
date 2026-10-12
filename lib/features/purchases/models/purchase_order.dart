import '../../../core/enums/app_enums.dart';

class PurchaseOrder {
  final String id;
  final String facilityId;
  final String purchaseOrderNumber;
  final String? supplierName;
  final String orderDate;
  final String? expectedDate;
  final PurchaseOrderStatus status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const PurchaseOrder({
    required this.id,
    required this.facilityId,
    required this.purchaseOrderNumber,
    this.supplierName,
    required this.orderDate,
    this.expectedDate,
    this.status = PurchaseOrderStatus.draft,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  PurchaseOrder copyWith({
    String? id,
    String? facilityId,
    String? purchaseOrderNumber,
    String? supplierName,
    String? orderDate,
    String? expectedDate,
    PurchaseOrderStatus? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      facilityId: facilityId ?? this.facilityId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      supplierName: supplierName ?? this.supplierName,
      orderDate: orderDate ?? this.orderDate,
      expectedDate: expectedDate ?? this.expectedDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facility_id': facilityId,
      'purchase_order_number': purchaseOrderNumber,
      'supplier_name': supplierName,
      'order_date': orderDate,
      'expected_date': expectedDate,
      'status': status.toDbString(),
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'] as String,
      facilityId: map['facility_id'] as String,
      purchaseOrderNumber: map['purchase_order_number'] as String,
      supplierName: map['supplier_name'] as String?,
      orderDate: map['order_date'] as String,
      expectedDate: map['expected_date'] as String?,
      status: PurchaseOrderStatus.fromDbString(map['status'] as String?),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
