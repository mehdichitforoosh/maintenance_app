class Location {
  final String id;
  final String facilityId;
  final String? parentLocationId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const Location({
    required this.id,
    required this.facilityId,
    this.parentLocationId,
    required this.name,
    this.code,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facility_id': facilityId,
      'parent_location_id': parentLocationId,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] as String,
      facilityId: map['facility_id'] as String,
      parentLocationId: map['parent_location_id'] as String?,
      name: map['name'] as String,
      code: map['code'] as String?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Location copyWith({
    String? parentLocationId,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return Location(
      id: id,
      facilityId: facilityId,
      parentLocationId: parentLocationId ?? this.parentLocationId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
