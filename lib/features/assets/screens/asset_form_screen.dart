import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/asset.dart';
import '../providers/asset_providers.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  final String? assetId;

  const AssetFormScreen({super.key, this.assetId});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _mfrController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _descController = TextEditingController();
  AssetType _assetType = AssetType.machine;
  AssetStatus _status = AssetStatus.active;
  bool _isLoading = false;
  Asset? _existingAsset;

  @override
  void initState() {
    super.initState();
    if (widget.assetId != null) {
      _loadAsset();
    }
  }

  Future<void> _loadAsset() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(assetRepositoryProvider);
      final asset = await repo.getAssetById(widget.assetId!);
      if (asset != null && mounted) {
        _existingAsset = asset;
        _nameController.text = asset.name;
        _codeController.text = asset.code;
        _mfrController.text = asset.manufacturer ?? '';
        _modelController.text = asset.model ?? '';
        _serialController.text = asset.serialNumber ?? '';
        _descController.text = asset.description ?? '';
        _assetType = asset.assetType;
        _status = asset.status;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _mfrController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility == null) return;
      final repo = ref.read(assetRepositoryProvider);

      if (_existingAsset != null) {
        final updated = _existingAsset!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          assetType: _assetType,
          status: _status,
          manufacturer: _mfrController.text.trim().isEmpty ? null : _mfrController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        );
        await repo.updateAsset(updated);
        ref.invalidate(assetDetailProvider(updated.id));
      } else {
        await repo.createAsset(
          facilityId: facility.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          assetType: _assetType,
          status: _status,
          manufacturer: _mfrController.text.trim().isEmpty ? null : _mfrController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        );
      }

      ref.invalidate(assetsProvider(facility.id));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.assetId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش تجهیز' : 'ثبت تجهیز جدید', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading && isEditing && _existingAsset == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'نام تجهیز *',
                        prefixIcon: Icon(EneftyIcons.cpu_bold),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => AppValidators.required(v, fieldName: 'نام تجهیز'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'کد تجهیز (یکتا) *',
                        prefixIcon: Icon(EneftyIcons.code_bold),
                        border: OutlineInputBorder(),
                      ),
                      validator: AppValidators.code,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AssetType>(
                      initialValue: _assetType,
                      decoration: const InputDecoration(
                        labelText: 'نوع تجهیز',
                        prefixIcon: Icon(EneftyIcons.setting_bold),
                        border: OutlineInputBorder(),
                      ),
                      items: AssetType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                      onChanged: (v) => setState(() => _assetType = v ?? AssetType.machine),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AssetStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'وضعیت',
                        prefixIcon: Icon(EneftyIcons.info_circle_bold),
                        border: OutlineInputBorder(),
                      ),
                      items: AssetStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                      onChanged: (v) => setState(() => _status = v ?? AssetStatus.active),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mfrController,
                      decoration: const InputDecoration(
                        labelText: 'سازنده / برند',
                        prefixIcon: Icon(EneftyIcons.building_bold),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'مدل',
                        prefixIcon: Icon(EneftyIcons.box_bold),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serialController,
                      decoration: const InputDecoration(
                        labelText: 'شماره سریال',
                        prefixIcon: Icon(EneftyIcons.document_text_bold),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'توضیحات',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: Icon(isEditing ? EneftyIcons.edit_2_bold : EneftyIcons.add_bold),
                      onPressed: _isLoading ? null : _save,
                      label: Text(isEditing ? 'بروزرسانی تجهیز' : 'ذخیره تجهیز'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
