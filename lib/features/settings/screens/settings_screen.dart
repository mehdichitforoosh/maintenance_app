import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../facilities/providers/facility_providers.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تنظیمات و امکانات بیشتر',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: facilityAsync.when(
        data: (facility) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Facility Hero Card
              const SectionHeader(title: 'اطلاعات کارگاه و کارخانه'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.05),
                        Colors.white,
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              EneftyIcons.building_bold,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facility?.name ?? 'کارگاه ثبت‌نشده',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  facility?.address ?? 'آدرس ثبت نشده است',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(
                              EneftyIcons.edit_2_outline,
                              size: 18,
                            ),
                            tooltip: 'ویرایش مشخصات کارگاه',
                            onPressed: () => context.push('/setup/facility'),
                          ),
                        ],
                      ),
                      if (facility?.description != null &&
                          facility!.description!.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          children: [
                            const Icon(
                              EneftyIcons.document_text_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                facility.description!,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Modules & Navigation Group
              const SectionHeader(title: 'مدیریت و ماژول‌های عملیاتی'),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: EneftyIcons.calendar_2_bold,
                      iconColor: const Color(0xFF2563EB),
                      title: 'برنامه‌های نگهداری پیشگیرانه (PM)',
                      subtitle: 'زمان‌بندی تقویمی، کارکردی و شرطی تجهیزات',
                      onTap: () => context.push('/maintenance-plans'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SettingsTile(
                      icon: EneftyIcons.location_bold,
                      iconColor: const Color(0xFF0D9488),
                      title: 'موقعیت‌ها و سالن‌های کارگاه',
                      subtitle: 'مدیریت ساختار مکان‌ها و سالن‌ها',
                      onTap: () => context.push('/locations'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SettingsTile(
                      icon: EneftyIcons.chart_2_bold,
                      iconColor: const Color(0xFF9333EA),
                      title: 'درخت سلسله‌مراتبی تجهیزات',
                      subtitle: 'مشاهده ساختار درختی والد و فرزند تجهیزات',
                      onTap: () => context.push('/assets/tree'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SettingsTile(
                      icon: EneftyIcons.shopping_cart_bold,
                      iconColor: const Color(0xFFEA580C),
                      title: 'سفارشات خرید و رسید کالا (PO)',
                      subtitle: 'مدیریت سفارشات تامین‌کنندگان و دریافت انبار',
                      onTap: () => context.push('/purchases'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SettingsTile(
                      icon: EneftyIcons.box_bold,
                      iconColor: const Color(0xFF4F46E5),
                      title: 'تعدیل و اصلاح موجودی انبار',
                      subtitle: 'ثبت ورود/خروج اصلاحی کالا و قطعات',
                      onTap: () => context.push('/inventory/adjustment'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SettingsTile(
                      icon: EneftyIcons.notification_bold,
                      iconColor: const Color(0xFFDC2626),
                      title: 'هشدارها و اعلان‌های فعال',
                      subtitle: 'بررسی هشدارهای سررسید، تأخیر و کمبود موجودی',
                      onTap: () => context.push('/alerts'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // System & Database Info
              const SectionHeader(title: 'سیستم و پایگاه داده'),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(
                      EneftyIcons.data_bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  title: Text(
                    'پایگاه داده محلی SQLite',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'نسخه 1.0.0 — سازگار با معماری آفلاین و همگام‌سازی ابری',
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('خطا: $e')),
      ),
    );
  }
}
