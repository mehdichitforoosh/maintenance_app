import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../facilities/providers/facility_providers.dart';
import '../repositories/backup_repository.dart';
import '../../../core/widgets/app_responsive_container.dart';
import 'widgets/backup_export_card.dart';
import 'widgets/backup_import_card.dart';
import 'widgets/backup_info_banner.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final BackupRepository _repository = BackupRepository();
  bool _isProcessing = false;

  void _refreshAllProviders() {
    ref.invalidate(primaryFacilityProvider);
  }

  Future<void> _shareBackupFile() async {
    setState(() => _isProcessing = true);
    try {
      await _repository.shareBackupFile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در اشتراک‌گذاری فایل پشتیبان: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportBackupFile() async {
    setState(() => _isProcessing = true);
    try {
      final file = await _repository.exportBackupToFile();
      if (!mounted || file == null) return;

      final filePath = file.path;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('فایل پشتیبان ذخیره شد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'فایل پشتیبان با موفقیت در حافظه دستگاه شما ذخیره گردید:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'می‌توانید این فایل را در پوشه Downloads مدیریت فایل پیدا کرده یا ارسال نمایید.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('مسیر فایل پشتیبان کپی شد!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('کپی مسیر فایل'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تأیید'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ذخیره فایل پشتیبان: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickAndImportFile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('هشدار بازیابی اطلاعات'),
        content: const Text(
          'با انتخاب فایل پشتیبان، تمام داده‌های فعلی برنامه جایگزین داده‌های فایل جدید خواهند شد. آیا مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('انتخاب فایل و جایگزینی'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await _repository.pickAndImportBackupFile();
      if (success) {
        _refreshAllProviders();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اطلاعات با موفقیت از فایل پشتیبان بازیابی شدند!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بازیابی اطلاعات از فایل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پشتیبان‌گیری و بازیابی'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          AppResponsiveContainer(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const BackupInfoBanner(),
                const SizedBox(height: 22),
                _buildSectionHeader(context, 'ایجاد پشتیبان'),
                const SizedBox(height: 8),
                BackupExportCard(
                  isProcessing: _isProcessing,
                  onShareBackupFilePressed: _shareBackupFile,
                  onExportBackupFilePressed: _exportBackupFile,
                ),
                const SizedBox(height: 22),
                _buildSectionHeader(context, 'بازیابی اطلاعات'),
                const SizedBox(height: 8),
                BackupImportCard(
                  isProcessing: _isProcessing,
                  onPickAndImportFilePressed: _pickAndImportFile,
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(150),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
