import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class BackupExportCard extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onShareBackupFilePressed;
  final VoidCallback onExportBackupFilePressed;

  const BackupExportCard({
    super.key,
    required this.isProcessing,
    required this.onShareBackupFilePressed,
    required this.onExportBackupFilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final accentColor = Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
                Theme.of(context).brightness == Brightness.dark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(25),
                child: const Icon(
                  EneftyIcons.export_3_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ایجاد پشتیبان (پشتیبان‌گیری)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ارسال به ایمیل، تلگرام یا ذخیره در حافظه دستگاه',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withAlpha(45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  EneftyIcons.document_upload_outline,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'برای نگهداری امن یا انتقال به گوشی دیگر، یک نسخه پشتیبان ایجاد و ارسال کنید.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : onShareBackupFilePressed,
              icon: const Icon(EneftyIcons.export_outline),
              label: const Text(
                'اشتراک‌گذاری فایل پشتیبان',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: isProcessing ? null : onExportBackupFilePressed,
              icon: const Icon(
                EneftyIcons.document_upload_outline,
                size: 18,
              ),
              label: const Text(
                'ذخیره مستقیم در پوشه Downloads',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
