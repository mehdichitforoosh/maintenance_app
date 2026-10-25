import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class BackupImportCard extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPickAndImportFilePressed;

  const BackupImportCard({
    super.key,
    required this.isProcessing,
    required this.onPickAndImportFilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final warningColor = Colors.orange.shade700;

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
                backgroundColor: Colors.orange.withAlpha(25),
                child: const Icon(
                  EneftyIcons.import_2_outline,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بازیابی اطلاعات',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'انتخاب فایل پشتیبان .json از حافظه دستگاه',
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
              color: warningColor.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warningColor.withAlpha(45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  EneftyIcons.warning_2_outline,
                  color: warningColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'هشدار: با بازیابی، داده‌های فعلی برنامه به کلی پاک شده و داده‌های فایل پشتیبان جایگزین می‌شوند.',
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
              onPressed: isProcessing ? null : onPickAndImportFilePressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
              ),
              icon: const Icon(EneftyIcons.folder_connection_outline),
              label: const Text(
                'انتخاب و بازیابی فایل پشتیبان',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
