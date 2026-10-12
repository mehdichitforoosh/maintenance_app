class Facility {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const Facility({
    required this.id,
    required this.name,
    this.description,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory Facility.fromMap(Map<String, dynamic> map) {
    return Facility(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Facility copyWith({
    String? name,
    String? description,
    String? address,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return Facility(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
