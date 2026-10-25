import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../facilities/providers/facility_providers.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);
    final themeMode = ref.watch(themeModeProvider);

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
              const SectionHeader(title: 'نمایش'),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    child: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                  ),
                  title: const Text(
                    'حالت نمایش',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('انتخاب پوسته روشن یا تیره برنامه'),
                  trailing: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('روشن'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('تیره'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {
                      themeMode == ThemeMode.dark ||
                              (themeMode == ThemeMode.system &&
                                  Theme.of(context).brightness ==
                                      Brightness.dark)
                          ? ThemeMode.dark
                          : ThemeMode.light,
                    },
                    onSelectionChanged: (selection) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(selection.first);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                    // gradient: LinearGradient(
                    //   colors: [
                    //     Theme.of(
                    //       context,
                    //     ).colorScheme.primary.withValues(alpha: 0.05),
                    //     Theme.of(context).colorScheme.surface,
                    //   ],
                    //   begin: Alignment.topRight,
                    //   end: Alignment.bottomLeft,
                    // ),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                            Icon(
                              EneftyIcons.document_text_outline,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                facility.description!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                    const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1,),
                    SettingsTile(
                      icon: EneftyIcons.location_bold,
                      iconColor: const Color(0xFF0D9488),
                      title: 'موقعیت‌ها و سالن‌های کارگاه',
                      subtitle: 'مدیریت ساختار مکان‌ها و سالن‌ها',
                      onTap: () => context.push('/locations'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1,),
                    SettingsTile(
                      icon: EneftyIcons.chart_2_bold,
                      iconColor: const Color(0xFF9333EA),
                      title: 'درخت سلسله‌مراتبی تجهیزات',
                      subtitle: 'مشاهده ساختار درختی والد و فرزند تجهیزات',
                      onTap: () => context.push('/assets/tree'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1,),
                    SettingsTile(
                      icon: EneftyIcons.shopping_cart_bold,
                      iconColor: const Color(0xFFEA580C),
                      title: 'سفارشات خرید و رسید کالا (PO)',
                      subtitle: 'مدیریت سفارشات تامین‌کنندگان و دریافت انبار',
                      onTap: () => context.push('/purchases'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1,),
                    SettingsTile(
                      icon: EneftyIcons.box_bold,
                      iconColor: const Color(0xFF4F46E5),
                      title: 'تعدیل و اصلاح موجودی انبار',
                      subtitle: 'ثبت ورود/خروج اصلاحی کالا و قطعات',
                      onTap: () => context.push('/inventory/adjustment'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1,),
                    SettingsTile(
                      icon: EneftyIcons.notification_bold,
                      iconColor: const Color(0xFFDC2626),
                      title: 'هشدارها و اعلان‌های فعال',
                      subtitle: 'بررسی هشدارهای سررسید، تأخیر و کمبود موجودی',
                      onTap: () => context.push('/alerts'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1,),
                    SettingsTile(
                      icon: EneftyIcons.chart_2_bold,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'گزارش‌های عملیاتی',
                      subtitle: 'گزارش تعمیرات، مصرف قطعات و رسیدهای خرید',
                      onTap: () => context.push('/reports'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1,),
                    SettingsTile(
                      icon: EneftyIcons.export_3_bold,
                      iconColor: const Color(0xFF16A34A),
                      title: 'پشتیبان‌گیری و بازیابی اطلاعات',
                      subtitle: 'خروجی گرفتن، اشتراک‌گذاری و بازیابی فایل پشتیبان دیتابیس',
                      onTap: () => context.push('/backup'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SectionHeader(title: 'اشتراک'),
              Card(
                child: SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'وضعیت اشتراک و دسترسی',
                  subtitle: 'مشاهده وضعیت دوره آزمایشی و امکانات خرید',
                  onTap: () => context.push('/subscription'),
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
