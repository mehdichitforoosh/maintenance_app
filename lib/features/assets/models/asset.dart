import '../../../core/enums/app_enums.dart';

class Asset {
  final String id;
  final String facilityId;
  final String? locationId;
  final String? parentAssetId;
  final String name;
  final String code;
  final AssetType assetType;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? installationDate;
  final String? commissioningDate;
  final AssetStatus status;
  final String? description;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const Asset({
    required this.id,
    required this.facilityId,
    this.locationId,
    this.parentAssetId,
    required this.name,
    required this.code,
    this.assetType = AssetType.other,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.installationDate,
    this.commissioningDate,
    this.status = AssetStatus.active,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facility_id': facilityId,
      'location_id': locationId,
      'parent_asset_id': parentAssetId,
      'name': name,
      'code': code,
      'asset_type': assetType.toDbString(),
      'manufacturer': manufacturer,
      'model': model,
      'serial_number': serialNumber,
      'installation_date': installationDate,
      'commissioning_date': commissioningDate,
      'status': status.toDbString(),
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      facilityId: map['facility_id'] as String,
      locationId: map['location_id'] as String?,
      parentAssetId: map['parent_asset_id'] as String?,
      name: map['name'] as String,
      code: map['code'] as String,
      assetType: AssetType.fromDbString(map['asset_type'] as String?),
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      serialNumber: map['serial_number'] as String?,
      installationDate: map['installation_date'] as String?,
      commissioningDate: map['commissioning_date'] as String?,
      status: AssetStatus.fromDbString(map['status'] as String?),
      description: map['description'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Asset copyWith({
    String? locationId,
    String? parentAssetId,
    String? name,
    String? code,
    AssetType? assetType,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? installationDate,
    String? commissioningDate,
    AssetStatus? status,
    String? description,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return Asset(
      id: id,
      facilityId: facilityId,
      locationId: locationId ?? this.locationId,
      parentAssetId: parentAssetId ?? this.parentAssetId,
      name: name ?? this.name,
      code: code ?? this.code,
      assetType: assetType ?? this.assetType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      installationDate: installationDate ?? this.installationDate,
      commissioningDate: commissioningDate ?? this.commissioningDate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
