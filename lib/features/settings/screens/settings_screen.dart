import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../facilities/providers/facility_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات و امکانات بیشتر', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: facilityAsync.when(
        data: (facility) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Facility Card
              const SectionHeader(title: 'اطلاعات کارگاه'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFDBEAFE),
                            child: Icon(EneftyIcons.building_bold, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(facility?.name ?? 'نامشخص', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('آدرس: ${facility?.address ?? 'ثبت نشده'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                            tooltip: 'ویرایش مشخصات کارگاه',
                            onPressed: () => context.push('/setup/facility'),
                          ),
                        ],
                      ),
                      if (facility?.description != null && facility!.description!.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text('توضیحات: ${facility.description}', style: const TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Modules & Navigation
              const SectionHeader(title: 'بخش‌های مدیریت و نگهداری'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: EneftyIcons.calendar_2_bold,
                      iconColor: Colors.blue,
                      title: 'برنامه‌های نگهداری پیشگیرانه (PM)',
                      subtitle: 'تعریف و مدیریت برنامه‌های دوره‌ای، کارکردی و شرطی',
                      onTap: () => context.push('/maintenance-plans'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsTile(
                      icon: EneftyIcons.location_bold,
                      iconColor: Colors.teal,
                      title: 'موقعیت‌ها و بخش‌های کارگاه',
                      subtitle: 'مدیریت درخت مکان‌ها و ساختار فیزیکی',
                      onTap: () => context.push('/locations'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsTile(
                      icon: EneftyIcons.chart_2_bold,
                      iconColor: Colors.purple,
                      title: 'درخت سلسله‌مراتبی تجهیزات',
                      subtitle: 'مشاهده ساختار والد/فرزند تجهیزات',
                      onTap: () => context.push('/assets/tree'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsTile(
                      icon: EneftyIcons.shopping_cart_bold,
                      iconColor: Colors.orange,
                      title: 'سفارشات خرید و رسید کالا',
                      subtitle: 'مدیریت سفارشات، تأمین‌کنندگان و دریافت انبار',
                      onTap: () => context.push('/purchases'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsTile(
                      icon: EneftyIcons.box_bold,
                      iconColor: Colors.indigo,
                      title: 'تعدیل و اصلاح موجودی انبار',
                      subtitle: 'ثبت ورود/خروج اصلاحی کالا',
                      onTap: () => context.push('/inventory/adjustment'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingsTile(
                      icon: EneftyIcons.notification_bold,
                      iconColor: Colors.red,
                      title: 'هشدارها و اعلان‌های فعال',
                      subtitle: 'بررسی هشدارهای سررسید، کمبود موجودی و شرطی',
                      onTap: () => context.push('/alerts'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Database & System Status
              const SectionHeader(title: 'سیستم و اطلاعات نرم‌افزار'),
              const Card(
                child: ListTile(
                  leading: Icon(EneftyIcons.data_bold, color: Colors.blueGrey),
                  title: Text('پایگاه داده محلی SQLite', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('نسخه 1.0.0 — سیستم نگهداری و تعمیرات (CMMS)'),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('خطا: $e')),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(EneftyIcons.arrow_left_3_outline, size: 18),
      onTap: onTap,
    );
  }
}
