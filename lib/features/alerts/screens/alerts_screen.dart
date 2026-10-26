import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_responsive_container.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/alert_event.dart';
import '../providers/alert_providers.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertStatus? _statusFilter;
  AlertSeverity? _severityFilter;

  @override
  Widget build(BuildContext context) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) {
          return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        }
        final alertsAsync = ref.watch(alertsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('اعلان‌ها و هشدارها'),
            actions: [
              IconButton(
                tooltip: 'به‌روزرسانی هشدارها',
                onPressed: () => ref.invalidate(alertsProvider(facility.id)),
                icon: const Icon(EneftyIcons.refresh_outline),
              ),
            ],
          ),
          body: alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) {
                return const AppEmptyState(
                  title: 'هیچ هشداری وجود ندارد',
                  message: 'وضعیت کارگاه و تجهیزات پایدار است.',
                  icon: EneftyIcons.notification_outline,
                );
              }
              final visibleAlerts = alerts.where((alert) {
                return (_statusFilter == null ||
                        alert.status == _statusFilter) &&
                    (_severityFilter == null ||
                        alert.severity == _severityFilter);
              }).toList();

              return AppResponsiveContainer(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          _statusFilterDropdown(),
                          _severityFilterDropdown(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visibleAlerts.isEmpty
                          ? const Center(
                              child: Text('هشداری با این فیلترها پیدا نشد.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: visibleAlerts.length,
                              itemBuilder: (context, index) => _alertTile(
                                context,
                                visibleAlerts[index],
                                facility.id,
                              ),
                            ),
                    ),
                  ],
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

  Widget _statusFilterDropdown() {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<AlertStatus?>(
        initialValue: _statusFilter,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'وضعیت'),
        items: [
          const DropdownMenuItem(value: null, child: Text('همه وضعیت‌ها')),
          ...AlertStatus.values.map(
            (status) => DropdownMenuItem(
              value: status,
              child: Text(status.displayName),
            ),
          ),
        ],
        onChanged: (status) => setState(() => _statusFilter = status),
      ),
    );
  }

  Widget _severityFilterDropdown() {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<AlertSeverity?>(
        initialValue: _severityFilter,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'شدت'),
        items: [
          const DropdownMenuItem(value: null, child: Text('همه شدت‌ها')),
          ...AlertSeverity.values.map(
            (severity) => DropdownMenuItem(
              value: severity,
              child: Text(severity.displayName),
            ),
          ),
        ],
        onChanged: (severity) => setState(() => _severityFilter = severity),
      ),
    );
  }

  Widget _alertTile(BuildContext context, AlertEvent alert, String facilityId) {
    final colorScheme = Theme.of(context).colorScheme;
    final severityColor = switch (alert.severity) {
      AlertSeverity.critical => colorScheme.error,
      AlertSeverity.warning => Colors.orange.shade800,
      AlertSeverity.info => colorScheme.primary,
    };
    final isOpen =
        alert.status == AlertStatus.active ||
        alert.status == AlertStatus.acknowledged;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              alert.severity == AlertSeverity.critical
                  ? EneftyIcons.danger_outline
                  : alert.severity == AlertSeverity.info
                  ? EneftyIcons.info_circle_outline
                  : EneftyIcons.warning_2_outline,
              color: severityColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alert.alertType.displayName} - ${alert.severity.displayName}\n'
                    '${alert.message ?? ''}\n'
                    'تاریخ: ${AppDateUtils.formatDisplay(alert.triggeredAt)}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isOpen)
              PopupMenuButton<AlertStatus>(
                tooltip: 'تغییر وضعیت هشدار',
                onSelected: (status) async {
                  try {
                    await ref
                        .read(alertActionsProvider)
                        .updateStatus(
                          alertId: alert.id,
                          facilityId: facilityId,
                          status: status,
                        );
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('خطا: $error')));
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (alert.status == AlertStatus.active)
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
                      : colorScheme.secondaryContainer,
                  side: BorderSide.none,
                ),
              )
            else
              Chip(
                label: Text(alert.status.displayName),
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
              ),
          ],
        ),
      ),
    );
  }
}
