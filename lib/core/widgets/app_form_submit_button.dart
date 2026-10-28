import 'package:flutter/material.dart';

class AppFormSubmitButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final bool isSubmitting;
  final VoidCallback onPressed;

  const AppFormSubmitButton({
    super.key,
    required this.label,
    this.icon,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : icon,
        label: Text(label),
      ),
    );
  }
}
