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

  const AppFormBody({
    super.key,
    required this.formKey,
    required this.children,
    this.isLoading = false,
    this.loadError,
    this.onRetry,
    this.padding = const EdgeInsets.all(16),
    this.safeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const AppLoading();
    if (loadError != null) {
      return AppErrorState(message: loadError!, onRetry: onRetry);
    }

    Widget body = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: padding,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );

    if (safeArea) body = SafeArea(child: body);
    return body;
  }
}
