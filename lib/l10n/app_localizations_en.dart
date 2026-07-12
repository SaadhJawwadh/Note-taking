// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Everything App';

  @override
  String get navNotes => 'Notes';

  @override
  String get navFinances => 'Finances';

  @override
  String get navTracker => 'Tracker';

  @override
  String get greetingMorning => 'Morning, Sun Shine!';

  @override
  String get greetingAfternoon => 'Had Lunch?';

  @override
  String get greetingEvening => 'Good Evening!';

  @override
  String get greetingNight => 'Time to sleep!';

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get newNote => 'New Note';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get search => 'Search';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get lockedNote => 'Locked note';

  @override
  String get appLocked => 'App Locked';

  @override
  String get unlock => 'Unlock';
}
