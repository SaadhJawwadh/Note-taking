import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          home: const HomeScreen(),
          locale: const Locale(
              'en', 'US'), // Force a default locale to ensure delegates match
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
