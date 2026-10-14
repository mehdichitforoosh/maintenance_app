import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';

class OnboardingBottomNavigation extends StatelessWidget {
  const OnboardingBottomNavigation({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    required this.onComplete,
    super.key,
  }) : assert(pageCount > 0),
       assert(currentPage >= 0 && currentPage < pageCount);

  final int currentPage;
  final int pageCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final isFirstPage = currentPage == 0;
    final isLastPage = currentPage == pageCount - 1;
    final compact = MediaQuery.sizeOf(context).height < 700;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 8 : 16),
      child: isLastPage
          ? SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                icon: const Icon(EneftyIcons.building_bold),
                label: const Text(
                  'شروع راه‌اندازی کارگاه',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: onComplete,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isFirstPage)
                  const SizedBox(width: 80)
                else
                  TextButton(
                    onPressed: onPrevious,
                    child: const Text('قبلی', style: TextStyle(fontSize: 18)),
                  ),
                TextButton(
                  onPressed: onNext,
                  child: const Text('بعدی', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
    );
  }
}
