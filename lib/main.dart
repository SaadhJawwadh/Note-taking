import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data/settings_provider.dart';
import 'data/transaction_category.dart';
import 'services/sms_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/app_lock_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/note_provider.dart';
import 'l10n/app_localizations.dart';

import 'package:flutter/foundation.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart' as backup;

import 'services/local_ai_service.dart';
import 'services/gemini_nano_service.dart';
import 'utils/widget_helper.dart';
import 'utils/app_globals.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Edge-to-edge: draw behind the system bars with a transparent nav bar
    // (also the enforced default on Android 15+; this keeps older versions
    // consistent).
    if (!kIsWeb && Platform.isAndroid) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );
    }

    // Initialize services but don't let them block the app if they fail —
    // or hang: the timeout guarantees the first frame always renders and
    // stragglers finish in the background.
    await Future.wait([
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
        Workmanager().initialize(backup.callbackDispatcher).catchError((e) => debugPrint('Workmanager error: $e')),
      TransactionCategory.reload().catchError((e) => debugPrint('Category reload error: $e')),
      SmsService.reloadSmsContacts().catchError((e) => debugPrint('SmsService reload error: $e')),
      if (!kIsWeb)
        NotificationService.initialize().catchError((e) => debugPrint('NotificationService error: $e')),
    ]).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('Startup init timed out; continuing to first frame');
      return const [];
    });
  } catch (e) {
    debugPrint('Critical initialization error: $e');
  }

  // Keep the finance widget's TODAY figure fresh across midnight even when
  // the app isn't opened; the widget redraws from prefs on its own cycle.
  // initialDelay keeps the task's first run (which opens the encrypted DB in
  // a background isolate) from racing the main isolate's DB open at cold
  // start — without it the two opens can deadlock before the first frame.
  if (!kIsWeb && Platform.isAndroid) {
    unawaited(
      Workmanager()
          .registerPeriodicTask(
            kWidgetRefreshTaskName,
            kWidgetRefreshTaskName,
            frequency: const Duration(hours: 4),
            initialDelay: const Duration(hours: 1),
            constraints: Constraints(networkType: NetworkType.notRequired),
            existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
          )
          .catchError((e) => debugPrint('Widget refresh task error: $e')),
    );
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalAiService>(create: (_) => GeminiNanoService()),
        ChangeNotifierProvider(
          create: (context) {
            final settings = SettingsProvider();
            final aiService = Provider.of<LocalAiService>(context, listen: false);
            settings.checkAiCoreSupport(aiService);
            return settings;
          },
        ),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: const NoteApp(),
    ),
  );
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final settings = Provider.of<SettingsProvider>(context);
        
        // Log for diagnostics in case of blank screen
        debugPrint('NoteApp Build: Dynamic Scheme: ${lightDynamic != null}, ThemeMode: ${settings.themeMode}');

        return MaterialApp(
          title: 'Everything App',
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          scaffoldMessengerKey: appScaffoldMessengerKey,
          theme: AppTheme.createTheme(lightDynamic, Brightness.light),
          darkTheme: AppTheme.createTheme(darkDynamic, Brightness.dark),
          themeMode: settings.themeMode,
          home: const HomeScreen(),
          builder: (context, child) {
            return AppLockScreen(child: child!);
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
          ],
        );
      },
    );
  }
}
