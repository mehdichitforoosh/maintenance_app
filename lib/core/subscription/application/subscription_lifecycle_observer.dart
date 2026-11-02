import 'dart:async';

import 'package:flutter/widgets.dart';

import 'subscription_service.dart';

class SubscriptionLifecycleObserver with WidgetsBindingObserver {
  SubscriptionLifecycleObserver({
    required this.subscriptionService,
    required this.onSubscriptionStateChecked,
  });

  final SubscriptionService subscriptionService;
  final VoidCallback onSubscriptionStateChecked;

  Future<void>? _checkInProgress;
  bool _checkAgain = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkForClockRollback());
    }
  }

  Future<void> checkForClockRollback() {
    final currentCheck = _checkInProgress;
    if (currentCheck != null) {
      _checkAgain = true;
      return currentCheck;
    }

    final check = _runChecks();
    late final Future<void> trackedCheck;
    trackedCheck = check.whenComplete(() {
      if (identical(_checkInProgress, trackedCheck)) {
        _checkInProgress = null;
      }
    });
    _checkInProgress = trackedCheck;
    return trackedCheck;
  }

  Future<void> _runChecks() async {
    do {
      _checkAgain = false;
      try {
        await subscriptionService.resetIfClockMovedBackwards();
      } catch (error, stackTrace) {
        _reportError(error, stackTrace, 'checking the device clock');
      }

      try {
        onSubscriptionStateChecked();
      } catch (error, stackTrace) {
        _reportError(error, stackTrace, 'refreshing subscription state');
      }
    } while (_checkAgain);
  }

  void _reportError(Object error, StackTrace stackTrace, String action) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'subscription lifecycle',
        context: ErrorDescription('while $action after app resume'),
      ),
    );
  }
}
