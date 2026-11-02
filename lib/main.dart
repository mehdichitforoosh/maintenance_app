import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import 'core/localizations/persian_localizations.dart';
import 'core/routes/app_router.dart';
import 'core/storage/database/database_helper.dart';
import 'core/storage/key_value_storage.dart';
import 'core/subscription/application/subscription_lifecycle_observer.dart';
import 'core/subscription/application/subscription_service.dart';
import 'core/subscription/data/local_subscription_state_store.dart';
import 'core/subscription/providers/subscription_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/facilities/repositories/facility_repository.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize resources for the app
  await DatabaseHelper.instance.initialize();
  await KeyValueStorage.initialize();
  await initializeDateFormatting('fa_IR');
  Intl.defaultLocale = 'fa_IR';

  final storage = KeyValueStorage.instance;
  // Local-only protection: if the device clock moved backwards, invalidate active
  // subscription windows so the app falls back to read-only mode.
  final subscriptionState = await SubscriptionService(
    store: LocalSubscriptionStateStore(),
    clock: () => DateTime.now().toUtc(),
  ).resetIfClockMovedBackwards();
  final initialLocation = !storage.isOnboardingCompleted
      ? subscriptionState.trialStartedAtUtc == null
            ? '/welcome'
            : '/onboarding'
      : storage.isFirstRun
      ? '/setup/facility'
      : await FacilityRepository().hasFacility()
      ? '/'
      : '/setup/facility';
  final appRouter = createAppRouter(initialLocation: initialLocation);

  runApp(ProviderScope(child: MyApp(router: appRouter)));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final SubscriptionLifecycleObserver _subscriptionLifecycleObserver;

  @override
  void initState() {
    super.initState();
    _subscriptionLifecycleObserver = SubscriptionLifecycleObserver(
      subscriptionService: ref.read(subscriptionServiceProvider),
      onSubscriptionStateChecked: () {
        if (!mounted) return;
        ref.invalidate(subscriptionStateProvider);
        ref.invalidate(subscriptionAccessProvider);
      },
    );
    WidgetsBinding.instance.addObserver(_subscriptionLifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_subscriptionLifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
      localizationsDelegates: const [
        CustomPersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: widget.router,
    );
  }
}
