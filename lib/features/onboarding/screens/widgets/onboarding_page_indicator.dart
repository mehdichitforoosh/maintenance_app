import 'package:flutter/material.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    required this.pageCount,
    required this.currentPage,
    super.key,
  }) : assert(pageCount > 0),
       assert(currentPage >= 0 && currentPage < pageCount);

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
