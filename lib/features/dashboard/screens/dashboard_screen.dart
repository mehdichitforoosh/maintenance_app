import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import 'widgets/dashboard_content.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) {
          return const Scaffold(
            body: AppLoading(message: 'در حال بررسی اطلاعات کارگاه...'),
          );
        }

        return DashboardContent(
          facilityId: facility.id,
          facilityName: facility.name,
        );
      },
      loading: () =>
          const Scaffold(body: AppLoading(message: 'در حال بارگذاری...')),
      error: (err, st) => Scaffold(
        body: AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(primaryFacilityProvider),
        ),
      ),
    );
  }
}
