import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/jalali_extensions.dart';
import '../../../core/subscription/application/subscription_policy.dart';
import '../../../core/subscription/domain/access_mode.dart';
import '../../../core/subscription/domain/subscription_state.dart';
import '../../../core/subscription/providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isStartingTrial = false;

  Future<void> _startTrial() async {
    setState(() => _isStartingTrial = true);
    try {
      await ref.read(subscriptionActionsProvider).startTrial();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('شروع دوره آزمایشی ناموفق بود: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingTrial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(subscriptionStateProvider);
    final accessAsync = ref.watch(subscriptionAccessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('اشتراک و دسترسی')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('خطا در دریافت وضعیت اشتراک: $error')),
        data: (state) => accessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('خطا در بررسی دسترسی: $error')),
          data: (access) => _buildStatus(context, state, access),
        ),
      ),
    );
  }

  Widget _buildStatus(
    BuildContext context,
    SubscriptionState? loadedState,
    AccessDecision access,
  ) {
    final state = loadedState ?? const SubscriptionState();
    final trialStarted = state.trialStartedAtUtc != null;
    final hasPaidEntitlement = state.entitlementStartedAtUtc != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusTitle(access.accessMode),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_statusDescription(access.reason)),
                if (state.trialEndsAtUtc != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'پایان دوره آزمایشی: ${state.trialEndsAtUtc!.toLocal().toShamsiDate()}',
                  ),
                ],
                if (state.entitlementEndsAtUtc != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'پایان اشتراک: ${state.entitlementEndsAtUtc!.toLocal().toShamsiDate()}',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!trialStarted && !hasPaidEntitlement && state.planId == null)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isStartingTrial ? null : _startTrial,
              icon: _isStartingTrial
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('شروع ۱۵ روز دسترسی کامل'),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'پرداخت و بازیابی خرید درون‌برنامه‌ای هنوز پشتیبانی نمی‌شود.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _statusTitle(AccessMode mode) => switch (mode) {
    AccessMode.fullAccess => 'دسترسی کامل',
    AccessMode.readOnly => 'حالت فقط‌خواندنی',
    AccessMode.trialNotStarted => 'دوره آزمایشی شروع نشده است',
  };

  String _statusDescription(String reason) => switch (reason) {
    'trial_active' => 'دوره آزمایشی فعال است و امکان ثبت تغییرات دارید.',
    'paid_active' => 'اشتراک فعال است و امکان ثبت تغییرات دارید.',
    'trial_expired' =>
      'دوره آزمایشی پایان یافته؛ اطلاعات همچنان قابل مشاهده است.',
    'revoked' =>
      'به دلیل تغییر ساعت دستگاه، اعتبار اشتراک لغو شده است. برای بازیابی دسترسی با پشتیبانی تماس بگیرید.',
    _ =>
      'می‌توانید اطلاعات را مشاهده کنید؛ برای ثبت تغییرات دوره آزمایشی را شروع کنید.',
  };
}
