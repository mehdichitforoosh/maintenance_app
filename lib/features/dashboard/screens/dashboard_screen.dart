import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../facilities/providers/facility_providers.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/setup/facility');
          });
          return const Scaffold(body: AppLoading(message: 'در حال بررسی اطلاعات کارگاه...'));
        }

        return _DashboardContent(facilityId: facility.id, facilityName: facility.name);
      },
      loading: () => const Scaffold(body: AppLoading(message: 'در حال بارگذاری...')),
      error: (err, st) => Scaffold(body: AppErrorState(message: err.toString(), onRetry: () => ref.invalidate(primaryFacilityProvider))),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final String facilityId;
  final String facilityName;

  const _DashboardContent({required this.facilityId, required this.facilityName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider(facilityId));
    final todayTasksAsync = ref.watch(dashboardTodayTasksProvider(facilityId));
    final lowStockAsync = ref.watch(lowStockItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(facilityName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(EneftyIcons.notification_outline),
            tooltip: 'اعلان‌ها و هشدارها',
            onPressed: () => context.push('/alerts'),
          ),
          IconButton(
            icon: const Icon(EneftyIcons.setting_2_outline),
            tooltip: 'تنظیمات و مدیریت',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider(facilityId));
          ref.invalidate(dashboardTodayTasksProvider(facilityId));
          ref.invalidate(lowStockItemsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Summary Cards
            summaryAsync.when(
              data: (summary) => GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [
                  _SummaryCard(
                    title: 'سررسید امروز',
                    count: summary['due_today'] ?? 0,
                    color: const Color(0xFFD97706),
                    icon: EneftyIcons.calendar_2_bold,
                    onTap: () => context.push('/work-orders'),
                  ),
                  _SummaryCard(
                    title: 'معوق و تأخیر',
                    count: summary['overdue'] ?? 0,
                    color: const Color(0xFFDC2626),
                    icon: EneftyIcons.danger_bold,
                    onTap: () => context.push('/work-orders'),
                  ),
                  _SummaryCard(
                    title: 'دستورکارهای باز',
                    count: summary['open_work_orders'] ?? 0,
                    color: const Color(0xFF2563EB),
                    icon: EneftyIcons.document_text_bold,
                    onTap: () => context.push('/work-orders'),
                  ),
                  _SummaryCard(
                    title: 'اقلام کم‌موجودی',
                    count: summary['low_stock'] ?? 0,
                    color: const Color(0xFF9333EA),
                    icon: EneftyIcons.box_bold,
                    onTap: () => context.push('/inventory'),
                  ),
                ],
              ),
              loading: () => const SizedBox(height: 150, child: AppLoading()),
              error: (e, _) => Text('خطا در بارگذاری خلاصه: $e'),
            ),
            const SizedBox(height: 24),

            // Quick Shortcuts
            const SectionHeader(title: 'میانبرهای سریع'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ShortcutButton(
                      icon: EneftyIcons.cpu_bold,
                      label: 'تجهیز جدید',
                      onTap: () => context.push('/assets/new'),
                    ),
                    _ShortcutButton(
                      icon: EneftyIcons.document_bold,
                      label: 'دستورکار جدید',
                      onTap: () => context.push('/work-orders/new'),
                    ),
                    _ShortcutButton(
                      icon: EneftyIcons.task_bold,
                      label: 'برنامه PM',
                      onTap: () => context.push('/maintenance-plans'),
                    ),
                    _ShortcutButton(
                      icon: EneftyIcons.box_add_bold,
                      label: 'کالای انبار',
                      onTap: () => context.push('/inventory/new'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Work Tasks
            const SectionHeader(title: 'کارهای امروز'),
            todayTasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(EneftyIcons.tick_circle_bold, color: Colors.green),
                          SizedBox(width: 8),
                          Text('هیچ وظیفه‌ای برای امروز سررسید نشده است.', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(EneftyIcons.task_square_bold, color: Color(0xFF2563EB)),
                        title: Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('تجهیز: ${t['asset_name']} | کد: ${t['work_order_number']}'),
                        trailing: const Icon(EneftyIcons.arrow_left_3_outline),
                        onTap: () => context.push('/work-orders/${t['work_order_id']}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Text('خطا: $e'),
            ),
            const SizedBox(height: 24),

            // Low Stock Alert Section
            const SectionHeader(title: 'هشدار موجودی انبار'),
            lowStockAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(EneftyIcons.box_bold, color: Colors.green),
                          SizedBox(width: 8),
                          Text('وضعیت موجودی تمام اقلام انبار مطلوب است.', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length > 3 ? 3 : items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(EneftyIcons.danger_bold, color: Color(0xFFDC2626)),
                        title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('موجودی: ${item['calculated_stock']} ${item['unit']} (حداقل: ${item['minimum_stock']})'),
                        trailing: OutlinedButton.icon(
                          icon: const Icon(EneftyIcons.shopping_cart_bold, size: 16),
                          label: const Text('سفارش خرید'),
                          onPressed: () => context.push('/purchases/new'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Text('خطا: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
