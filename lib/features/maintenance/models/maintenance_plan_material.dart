class MaintenancePlanMaterial {
  final String id;
  final String maintenancePlanId;
  final String itemId;
  final double plannedQuantity;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const MaintenancePlanMaterial({
    required this.id,
    required this.maintenancePlanId,
    required this.itemId,
    required this.plannedQuantity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maintenance_plan_id': maintenancePlanId,
      'item_id': itemId,
      'planned_quantity': plannedQuantity,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory MaintenancePlanMaterial.fromMap(Map<String, dynamic> map) {
    return MaintenancePlanMaterial(
      id: map['id'] as String,
      maintenancePlanId: map['maintenance_plan_id'] as String,
      itemId: map['item_id'] as String,
      plannedQuantity: (map['planned_quantity'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
