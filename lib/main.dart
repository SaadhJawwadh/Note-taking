import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';

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
        return MaterialApp(
          title: 'Note Book',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.createTheme(lightDynamic, Brightness.light),
          darkTheme: AppTheme.createTheme(darkDynamic, Brightness.dark),
          themeMode: Provider.of<SettingsProvider>(context).themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
