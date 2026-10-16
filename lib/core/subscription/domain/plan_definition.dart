import 'plan_id.dart';

class PlanDefinition {
  final SubscriptionPlanId id;
  final String title;
  final String description;
  final Duration? trialDuration;

  const PlanDefinition({
    required this.id,
    required this.title,
    required this.description,
    this.trialDuration,
  });

  static const List<PlanDefinition> builtIn = [
    PlanDefinition(
      id: SubscriptionPlanId.trial,
      title: 'رایگان - ۱۵ روز آزمایشی',
      description: '۱۵ روز دسترسی کامل',
      trialDuration: Duration(days: 15),
    ),
    PlanDefinition(
      id: SubscriptionPlanId.monthly,
      title: 'ماهیانه',
      description: 'اشتراک ماهانه',
    ),
    PlanDefinition(
      id: SubscriptionPlanId.threeMonths,
      title: '۳ ماهه',
      description: 'اشتراک ۳ ماهه',
    ),
    PlanDefinition(
      id: SubscriptionPlanId.sixMonths,
      title: '۶ ماهه',
      description: 'اشتراک ۶ ماهه',
    ),
    PlanDefinition(
      id: SubscriptionPlanId.yearly,
      title: 'سالیانه',
      description: 'اشتراک سالیانه',
    ),
  ];
}

