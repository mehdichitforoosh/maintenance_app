import 'package:flutter/material.dart';
import 'report_category_sections.dart' show ReportCategory;

enum ReportPeriod { week, month, year, custom }

class ReportPeriodChips extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onSelected;

  const ReportPeriodChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _PeriodChip(
          label: 'هفتگی',
          value: ReportPeriod.week,
          selected: selected,
          onSelected: onSelected,
        ),
        _PeriodChip(
          label: 'ماهانه',
          value: ReportPeriod.month,
          selected: selected,
          onSelected: onSelected,
        ),
        _PeriodChip(
          label: 'سالانه',
          value: ReportPeriod.year,
          selected: selected,
          onSelected: onSelected,
        ),
        _PeriodChip(
          label: 'دلخواه',
          value: ReportPeriod.custom,
          selected: selected,
          onSelected: onSelected,
          icon: Icons.date_range_outlined,
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final ReportPeriod value;
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onSelected;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 16),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: TextStyle(
        color: selected == value
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: selected == value ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
      side: BorderSide(
        color: selected == value
            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4)
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      shape: const StadiumBorder(),
    );
  }
}

class ReportCategoryPicker extends StatelessWidget {
  final ReportCategory selected;
  final ValueChanged<ReportCategory> onSelected;

  const ReportCategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final category in ReportCategory.values) ...[
          if (category != ReportCategory.values.first) const SizedBox(width: 8),
          Expanded(
            child: _CategoryChip(
              category: category,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ReportCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, compactLabel, icon) = switch (category) {
      ReportCategory.workOrders => ('تعمیرات', 'تعمیرات', Icons.build_outlined),
      ReportCategory.materials => (
        'مصرف قطعات',
        'مصرف',
        Icons.inventory_2_outlined,
      ),
      ReportCategory.purchases => (
        'دریافت خرید',
        'خرید',
        Icons.local_shipping_outlined,
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected
                  ? colors.primary.withValues(alpha: 0.4)
                  : colors.outlineVariant,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      compactLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
