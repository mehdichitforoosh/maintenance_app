import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/key_value_storage.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_body.dart';
import '../../../core/widgets/app_form_submit_button.dart';
import '../models/facility.dart';
import '../providers/facility_providers.dart';

class FacilitySetupScreen extends ConsumerStatefulWidget {
  const FacilitySetupScreen({super.key});

  @override
  ConsumerState<FacilitySetupScreen> createState() =>
      _FacilitySetupScreenState();
}

class _FacilitySetupScreenState extends ConsumerState<FacilitySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;
  Facility? _existingFacility;

  @override
  void initState() {
    super.initState();
    _loadExistingFacility();
  }

  Future<void> _loadExistingFacility() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final facility = await ref.read(primaryFacilityProvider.future);
      if (facility != null && mounted) {
        _existingFacility = facility;
        _nameController.text = facility.name;
        _descController.text = facility.description ?? '';
        _addressController.text = facility.address ?? '';
      }
    } catch (error) {
      if (mounted) _loadError = 'بارگذاری اطلاعات کارگاه ناموفق بود: $error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _loadError != null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      if (_existingFacility != null) {
        final updated = _existingFacility!.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );
        await ref.read(facilityActionsProvider).update(updated);
      } else {
        await ref
            .read(facilityActionsProvider)
            .create(
              name: _nameController.text.trim(),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              address: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
            );
      }

      await KeyValueStorage.instance.setFacilitySetupCompleted();
      await ref.read(primaryFacilityProvider.future);

      if (mounted) {
        if (_existingFacility != null) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره مشخصات کارگاه: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingFacility != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'ویرایش مشخصات کارگاه' : 'راه‌اندازی کارگاه / کارخانه',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AppFormBody(
        formKey: _formKey,
        isLoading: _isLoading,
        loadError: _loadError,
        onRetry: _loadExistingFacility,
        padding: const EdgeInsets.all(24),
        safeArea: true,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Icon(EneftyIcons.buildings_2_outline, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            isEditing
                ? 'ویرایش اطلاعات عمومی کارگاه'
                : 'خوش آمدید به سیستم نگهداری و تعمیرات',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isEditing
                ? 'می‌توانید نام، آدرس و توضیحات کارگاه خود را تغییر دهید.'
                : 'لطفاً مشخصات کارگاه یا کارخانه خود را جهت شروع کار ثبت کنید.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'نام کارگاه / کارخانه *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(EneftyIcons.building_outline),
            ),
            validator: (v) =>
                AppValidators.required(v, fieldName: 'نام کارگاه'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'توضیحات کارگاه',
              border: OutlineInputBorder(),
              prefixIcon: Icon(EneftyIcons.document_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'آدرس موقعیت',
              border: OutlineInputBorder(),
              prefixIcon: Icon(EneftyIcons.location_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          AppFormSubmitButton(
            isSubmitting: _isSubmitting,
            onPressed: _submit,
            label: isEditing ? 'بروزرسانی کارگاه' : 'ذخیره و ورود به سیستم',
          ),
        ],
      ),
    );
  }
}
