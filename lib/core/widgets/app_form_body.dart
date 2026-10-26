import 'package:flutter/material.dart';

import 'app_error_state.dart';
import 'app_loading.dart';

class AppFormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final bool isLoading;
  final String? loadError;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;
  final bool safeArea;
  final double? maxWidth;

  const AppFormBody({
    super.key,
    required this.formKey,
    required this.children,
    this.isLoading = false,
    this.loadError,
    this.onRetry,
    this.padding = const EdgeInsets.all(16),
    this.safeArea = false,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const AppLoading();
    if (loadError != null) {
      return AppErrorState(message: loadError!, onRetry: onRetry);
    }

    Widget content = Padding(
      padding: padding,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );

    if (maxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    Widget body = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: content,
    );

    if (safeArea) body = SafeArea(child: body);
    return body;
  }
}
