import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/core/subscription/application/subscription_policy.dart';
import 'package:maintenance_app/core/subscription/application/subscription_lifecycle_observer.dart';
import 'package:maintenance_app/core/subscription/application/subscription_service.dart';
import 'package:maintenance_app/core/subscription/data/subscription_state_store.dart';
import 'package:maintenance_app/core/subscription/domain/access_mode.dart';
import 'package:maintenance_app/core/subscription/domain/subscription_state.dart';
import 'package:maintenance_app/core/subscription/domain/subscription_status.dart';

void main() {
  group('SubscriptionService', () {
    test('starts a single 15-day trial', () async {
      final store = _MemorySubscriptionStore();
      var now = DateTime.utc(2026, 10, 21);
      final service = SubscriptionService(store: store, clock: () => now);

      final started = await service.startTrial();
      now = now.add(const Duration(days: 2));
      final repeated = await service.startTrial();

      expect(started.status, SubscriptionStatus.trialing);
      expect(started.trialStartedAtUtc, DateTime.utc(2026, 10, 21));
      expect(started.trialEndsAtUtc, DateTime.utc(2026, 11, 5));
      expect(repeated.trialStartedAtUtc, started.trialStartedAtUtc);
      expect(repeated.trialEndsAtUtc, started.trialEndsAtUtc);
    });

    test('clears entitlements when the device clock moves backwards', () async {
      final store = _MemorySubscriptionStore(
        SubscriptionState(
          planId: 'trial',
          status: SubscriptionStatus.trialing,
          trialStartedAtUtc: DateTime.utc(2026, 10, 20),
          trialEndsAtUtc: DateTime.utc(2026, 11, 4),
          entitlementStartedAtUtc: DateTime.utc(2026, 10, 20),
          entitlementEndsAtUtc: DateTime.utc(2027, 10, 20),
          lastSeenAtUtc: DateTime.utc(2026, 10, 21),
        ),
      );
      final service = SubscriptionService(
        store: store,
        clock: () => DateTime.utc(2026, 10, 19),
      );

      final state = await service.resetIfClockMovedBackwards();

      expect(state.trialStartedAtUtc, DateTime.utc(2026, 10, 20));
      expect(state.trialEndsAtUtc, isNull);
      expect(state.entitlementStartedAtUtc, isNull);
      expect(state.entitlementEndsAtUtc, isNull);
      expect(state.status, SubscriptionStatus.revoked);
      expect(state.lastSeenAtUtc, DateTime.utc(2026, 10, 19));
      expect(await store.load(), state);

      final stillRevoked = await service.startTrial();
      expect(stillRevoked.status, SubscriptionStatus.revoked);
      expect(stillRevoked.trialEndsAtUtc, isNull);
    });

    test('updates the last-seen checkpoint when the clock is valid', () async {
      final store = _MemorySubscriptionStore(
        SubscriptionState(
          planId: 'trial',
          status: SubscriptionStatus.trialing,
          trialStartedAtUtc: DateTime.utc(2026, 10, 20),
          trialEndsAtUtc: DateTime.utc(2026, 11, 4),
          lastSeenAtUtc: DateTime.utc(2026, 10, 21),
        ),
      );
      final service = SubscriptionService(
        store: store,
        clock: () => DateTime.utc(2026, 10, 22),
      );

      final state = await service.resetIfClockMovedBackwards();

      expect(state.status, SubscriptionStatus.trialing);
      expect(state.trialEndsAtUtc, DateTime.utc(2026, 11, 4));
      expect(state.lastSeenAtUtc, DateTime.utc(2026, 10, 22));
      expect(await store.load(), state);
    });

    test('initializes the last-seen checkpoint when no state exists', () async {
      final store = _MemorySubscriptionStore();
      final service = SubscriptionService(
        store: store,
        clock: () => DateTime.utc(2026, 10, 22),
      );

      final state = await service.resetIfClockMovedBackwards();

      expect(state.status, SubscriptionStatus.notStarted);
      expect(state.lastSeenAtUtc, DateTime.utc(2026, 10, 22));
      expect(await store.load(), state);
    });
  });

  group('SubscriptionLifecycleObserver', () {
    test('checks and refreshes subscription state on resume', () async {
      final store = _MemorySubscriptionStore();
      var now = DateTime.utc(2026, 10, 22);
      var refreshCount = 0;
      final observer = SubscriptionLifecycleObserver(
        subscriptionService: SubscriptionService(
          store: store,
          clock: () => now,
        ),
        onSubscriptionStateChecked: () => refreshCount++,
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(store.saveCount, 0);
      expect(refreshCount, 0);

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await store.firstSave;
      await Future<void>.delayed(Duration.zero);

      expect(store.state?.lastSeenAtUtc, now);
      expect(refreshCount, 1);
    });

    test(
      'serializes repeated resume checks and runs a follow-up check',
      () async {
        final store = _DelayedSubscriptionStore();
        var refreshCount = 0;
        final observer = SubscriptionLifecycleObserver(
          subscriptionService: SubscriptionService(
            store: store,
            clock: () => DateTime.utc(2026, 10, 22),
          ),
          onSubscriptionStateChecked: () => refreshCount++,
        );

        final firstCheck = observer.checkForClockRollback();
        await store.firstLoadStarted.future;
        final repeatedCheck = observer.checkForClockRollback();
        store.releaseFirstLoad.complete();
        await Future.wait([firstCheck, repeatedCheck]);

        expect(store.loadCount, 2);
        expect(refreshCount, 2);
      },
    );

    test(
      'reports check failures and still refreshes subscription providers',
      () async {
        final originalHandler = FlutterError.onError;
        final reportedErrors = <FlutterErrorDetails>[];
        FlutterError.onError = reportedErrors.add;
        var refreshCount = 0;
        final observer = SubscriptionLifecycleObserver(
          subscriptionService: SubscriptionService(
            store: _ThrowingSubscriptionStore(),
            clock: () => DateTime.utc(2026, 10, 22),
          ),
          onSubscriptionStateChecked: () => refreshCount++,
        );

        try {
          await observer.checkForClockRollback();
        } finally {
          FlutterError.onError = originalHandler;
        }

        expect(reportedErrors, hasLength(1));
        expect(reportedErrors.single.exception, isA<StateError>());
        expect(refreshCount, 1);
      },
    );
  });

  group('SubscriptionPolicy', () {
    test('grants access only while the trial is active', () {
      const policy = SubscriptionPolicy();
      final state = SubscriptionState(
        status: SubscriptionStatus.trialing,
        trialStartedAtUtc: DateTime.utc(2026, 10, 1),
        trialEndsAtUtc: DateTime.utc(2026, 10, 16),
      );

      expect(
        policy.evaluate(state, DateTime.utc(2026, 10, 15)).accessMode,
        AccessMode.fullAccess,
      );
      expect(
        policy.evaluate(state, DateTime.utc(2026, 10, 16)).accessMode,
        AccessMode.readOnly,
      );
      expect(
        policy
            .evaluate(
              SubscriptionState(
                planId: 'trial',
                status: SubscriptionStatus.revoked,
                trialStartedAtUtc: DateTime.utc(2026, 10, 1),
              ),
              DateTime.utc(2026, 10, 15),
            )
            .accessMode,
        AccessMode.readOnly,
      );
    });
  });
}

class _MemorySubscriptionStore implements SubscriptionStateStore {
  SubscriptionState? state;
  final Completer<void> _firstSave = Completer<void>();
  int saveCount = 0;

  _MemorySubscriptionStore([this.state]);

  Future<void> get firstSave => _firstSave.future;

  @override
  Future<SubscriptionState?> load() async => state;

  @override
  Future<void> save(SubscriptionState state) async {
    this.state = state;
    saveCount++;
    if (!_firstSave.isCompleted) _firstSave.complete();
  }
}

class _DelayedSubscriptionStore extends _MemorySubscriptionStore {
  final Completer<void> firstLoadStarted = Completer<void>();
  final Completer<void> releaseFirstLoad = Completer<void>();
  int loadCount = 0;

  @override
  Future<SubscriptionState?> load() async {
    loadCount++;
    if (loadCount == 1) {
      firstLoadStarted.complete();
      await releaseFirstLoad.future;
    }
    return state;
  }
}

class _ThrowingSubscriptionStore implements SubscriptionStateStore {
  @override
  Future<SubscriptionState?> load() async {
    throw StateError('Test storage failure');
  }

  @override
  Future<void> save(SubscriptionState state) async {}
}
