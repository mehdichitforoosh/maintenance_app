class AssetReading {
  final String id;
  final String assetId;
  final String metricName;
  final double value;
  final String unit;
  final String recordedAt;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const AssetReading({
    required this.id,
    required this.assetId,
    required this.metricName,
    required this.value,
    required this.unit,
    required this.recordedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'recorded_at': recordedAt,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory AssetReading.fromMap(Map<String, dynamic> map) {
    return AssetReading(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      metricName: map['metric_name'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      recordedAt: map['recorded_at'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
