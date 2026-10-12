import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/work_order_providers.dart';

class WorkOrderListScreen extends ConsumerWidget {
  const WorkOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final woAsync = ref.watch(workOrdersProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('دستورکارهای تعمیراتی', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: woAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return AppEmptyState(
                  title: 'دستورکاری ثبت نشده است',
                  message: 'برای شروع، دستورکار جدیدی ایجاد کنید.',
                  actionLabel: 'ایجاد دستورکار',
                  onActionPressed: () => context.push('/work-orders/new'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final wo = orders[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDBEAFE),
                        child: Icon(EneftyIcons.document_text_bold, color: Color(0xFF2563EB)),
                      ),
                      title: Text('${wo.workOrderNumber}: ${wo.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('نوع: ${wo.workOrderType.displayName} | وضعیت: ${wo.status.displayName} | اولویت: ${wo.priority.displayName}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                            tooltip: 'ویرایش دستورکار',
                            onPressed: () => context.push('/work-orders/${wo.id}/edit'),
                          ),
                          const Icon(EneftyIcons.arrow_left_3_outline, size: 18),
                        ],
                      ),
                      onTap: () => context.push('/work-orders/${wo.id}'),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/work-orders/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
