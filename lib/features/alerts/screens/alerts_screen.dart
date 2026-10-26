import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_responsive_container.dart';
import '../../facilities/providers/facility_providers.dart';
import '../providers/alert_providers.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) {
          return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        }
        final alertsAsync = ref.watch(alertsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(title: const Text('هشدارها و اطلاعیه‌های سیستم')),
          body: alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) {
                return const AppEmptyState(
                  title: 'هیچ هشداری وجود ندارد',
                  message: 'وضعیت کارگاه و تجهیزات پایدار است.',
                  icon: Icons.notifications_none,
                );
              }
              return AppResponsiveContainer(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final isCritical = alert.severity == AlertSeverity.critical;
                    return Card(
                      color: isCritical ? Colors.red[50] : null,
                      child: ListTile(
                        leading: Icon(
                          isCritical
                              ? Icons.error_outline
                              : Icons.warning_amber_rounded,
                          color: isCritical ? Colors.red : Colors.orange,
                        ),
                        title: Text(
                          alert.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${alert.message ?? ''}\n'
                          'تاریخ: ${AppDateUtils.formatDisplay(alert.triggeredAt)}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<AlertStatus>(
                          onSelected: (status) async {
                            try {
                              await ref
                                  .read(alertActionsProvider)
                                  .updateStatus(
                                    alertId: alert.id,
                                    facilityId: facility.id,
                                    status: status,
                                  );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('خطا: $error')),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: AlertStatus.acknowledged,
                              child: Text('تایید هشدار'),
                            ),
                            const PopupMenuItem(
                              value: AlertStatus.resolved,
                              child: Text('برطرف شده'),
                            ),
                            const PopupMenuItem(
                              value: AlertStatus.dismissed,
                              child: Text('رد کردن'),
                            ),
                          ],
                          child: Chip(
                            label: Text(alert.status.displayName),
                            backgroundColor: alert.status == AlertStatus.active
                                ? Colors.orange[100]
                                : Colors.green[100],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}
