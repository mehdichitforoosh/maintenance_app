class WorkOrderMaterial {
  final String id;
  final String workOrderTaskId;
  final String itemId;
  final double? plannedQuantity;
  final double? actualQuantity;
  final double? unitCostAtUse;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const WorkOrderMaterial({
    required this.id,
    required this.workOrderTaskId,
    required this.itemId,
    this.plannedQuantity,
    this.actualQuantity,
    this.unitCostAtUse,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'work_order_task_id': workOrderTaskId,
      'item_id': itemId,
      'planned_quantity': plannedQuantity,
      'actual_quantity': actualQuantity,
      'unit_cost_at_use': unitCostAtUse,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory WorkOrderMaterial.fromMap(Map<String, dynamic> map) {
    return WorkOrderMaterial(
      id: map['id'] as String,
      workOrderTaskId: map['work_order_task_id'] as String,
      itemId: map['item_id'] as String,
      plannedQuantity: (map['planned_quantity'] as num?)?.toDouble(),
      actualQuantity: (map['actual_quantity'] as num?)?.toDouble(),
      unitCostAtUse: (map['unit_cost_at_use'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
