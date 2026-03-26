import 'package:flutter/material.dart';
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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return true;
  });
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize services but don't let them block the app if they fail
    await Future.wait([
      Workmanager().initialize(callbackDispatcher, isInDebugMode: false).catchError((e) => debugPrint('Workmanager error: $e')),
      TransactionCategory.reload().catchError((e) => debugPrint('Category reload error: $e')),
      SmsService.reloadSmsContacts().catchError((e) => debugPrint('SmsService reload error: $e')),
    ]);
  } catch (e) {
    debugPrint('Critical initialization error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
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
          title: 'Note Book',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.createTheme(
            lightDynamic,
            Brightness.light,
            settings.fontFamily,
          ),
          darkTheme: AppTheme.createTheme(
            darkDynamic,
            Brightness.dark,
            settings.fontFamily,
          ),
          themeMode: settings.themeMode,
          home: const AppLockScreen(child: HomeScreen()),
          locale: const Locale('en', 'US'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            ...FlutterQuillLocalizations.supportedLocales,
          ],
        );
      },
    );
  }
}
