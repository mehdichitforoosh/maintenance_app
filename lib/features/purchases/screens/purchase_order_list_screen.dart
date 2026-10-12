import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/purchase_providers.dart';

class PurchaseOrderListScreen extends ConsumerWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final poAsync = ref.watch(purchaseOrdersProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('سفارشات خرید (PO)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: poAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return AppEmptyState(
                  title: 'سفارش خریدی ثبت نشده است',
                  message: 'برای تامین قطعات و اقلام انبار، سفارش خرید جدید ثبت کنید.',
                  actionLabel: 'ثبت سفارش خرید',
                  onActionPressed: () => context.push('/purchases/new'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final po = orders[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDBEAFE),
                        child: Icon(EneftyIcons.shopping_cart_bold, color: Color(0xFF2563EB)),
                      ),
                      title: Text('${po.purchaseOrderNumber}${po.supplierName != null ? ' - ${po.supplierName}' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('تاریخ: ${po.orderDate} | وضعیت: ${po.status.displayName}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(EneftyIcons.edit_2_outline, color: Color(0xFF2563EB)),
                            tooltip: 'ویرایش سفارش',
                            onPressed: () => context.push('/purchases/${po.id}/edit'),
                          ),
                          const Icon(EneftyIcons.arrow_left_3_outline, size: 18),
                        ],
                      ),
                      onTap: () => context.push('/purchases/${po.id}'),
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/purchases/new'),
            child: const Icon(EneftyIcons.add_bold),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
