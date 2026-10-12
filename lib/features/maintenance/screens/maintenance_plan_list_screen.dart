import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/maintenance_providers.dart';

class MaintenancePlanListScreen extends ConsumerWidget {
  const MaintenancePlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final plansAsync = ref.watch(allFacilityPlansProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('برنامه‌های نگهداری پیشگیرانه (PM)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: plansAsync.when(
            data: (plans) {
              if (plans.isEmpty) {
                return AppEmptyState(
                  title: 'برنامه PM ثبت نشده است',
                  message: 'می‌توانید برنامه زمان‌بندی جدیدی برای نگهداری تجهیزات تعریف کنید.',
                  actionLabel: 'افزودن برنامه PM',
                  onActionPressed: () => context.push('/maintenance-plans/new'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDBEAFE),
                        child: Icon(EneftyIcons.calendar_2_bold, color: Color(0xFF2563EB)),
                      ),
                      title: Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('زمان‌بندی: ${plan.scheduleType.displayName} | فعالیت: ${plan.activityType.displayName} | اولویت: ${plan.priority.displayName}'),
                      trailing: IconButton(
                        icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                        tooltip: 'ویرایش برنامه PM',
                        onPressed: () => context.push('/maintenance-plans/${plan.id}/edit?assetId=${plan.assetId}'),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/maintenance-plans/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
