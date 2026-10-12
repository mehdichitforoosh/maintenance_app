import '../../../core/enums/app_enums.dart';

class InventoryItem {
  final String id;
  final String name;
  final String code;
  final ItemType itemType;
  final String unit;
  final String? description;
  final double minimumStock;
  final double? defaultUnitCost;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.code,
    this.itemType = ItemType.consumable,
    required this.unit,
    this.description,
    this.minimumStock = 0.0,
    this.defaultUnitCost,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'item_type': itemType.toDbString(),
      'unit': unit,
      'description': description,
      'minimum_stock': minimumStock,
      'default_unit_cost': defaultUnitCost,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      itemType: ItemType.fromDbString(map['item_type'] as String?),
      unit: map['unit'] as String,
      description: map['description'] as String?,
      minimumStock: (map['minimum_stock'] as num?)?.toDouble() ?? 0.0,
      defaultUnitCost: (map['default_unit_cost'] as num?)?.toDouble(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  InventoryItem copyWith({
    String? name,
    String? code,
    ItemType? itemType,
    String? unit,
    String? description,
    double? minimumStock,
    double? defaultUnitCost,
    bool? isActive,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      itemType: itemType ?? this.itemType,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      minimumStock: minimumStock ?? this.minimumStock,
      defaultUnitCost: defaultUnitCost ?? this.defaultUnitCost,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
