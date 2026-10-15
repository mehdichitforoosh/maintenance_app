import 'package:flutter/material.dart';

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.compact,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 112.0 : 140.0;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  image: true,
                  label: title,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: iconSize / 2, color: color),
                  ),
                ),
                SizedBox(height: compact ? 20 : 32),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
