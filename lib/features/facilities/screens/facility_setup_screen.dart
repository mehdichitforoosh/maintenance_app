import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/key_value_storage.dart';
import '../../../core/utils/validators.dart';
import '../providers/facility_providers.dart';

class FacilitySetupScreen extends ConsumerStatefulWidget {
  const FacilitySetupScreen({super.key});

  @override
  ConsumerState<FacilitySetupScreen> createState() => _FacilitySetupScreenState();
}

class _FacilitySetupScreenState extends ConsumerState<FacilitySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(facilityRepositoryProvider);
      await repo.createFacility(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      await KeyValueStorage.instance.setOnboardingCompleted();
      ref.invalidate(primaryFacilityProvider);
      await ref.read(primaryFacilityProvider.future);

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ایجاد کارگاه: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('راه‌اندازی کارگاه / کارخانه', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(EneftyIcons.building_bold, size: 48, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 20),
                Text(
                  'خوش آمدید به سیستم نگهداری و تعمیرات (CMMS)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'لطفاً مشخصات کارگاه یا کارخانه خود را جهت شروع کار ثبت کنید.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'نام کارگاه / کارخانه *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(EneftyIcons.building_bold),
                  ),
                  validator: (v) => AppValidators.required(v, fieldName: 'نام کارگاه'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات کارگاه',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(EneftyIcons.document_bold),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'آدرس موقعیت',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(EneftyIcons.location_bold),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: _isLoading ? const SizedBox.shrink() : const Icon(EneftyIcons.tick_circle_bold),
                  onPressed: _isLoading ? null : _submit,
                  label: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('ذخیره و ورود به سیستم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
