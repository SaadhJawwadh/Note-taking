// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Everything App';

  @override
  String get navNotes => 'குறிப்புகள்';

  @override
  String get navFinances => 'நிதி';

  @override
  String get navTracker => 'கண்காணிப்பு';

  @override
  String get greetingMorning => 'காலை வணக்கம்!';

  @override
  String get greetingAfternoon => 'மதிய உணவு சாப்பிட்டீர்களா?';

  @override
  String get greetingEvening => 'மாலை வணக்கம்!';

  @override
  String get greetingNight => 'தூங்க வேண்டிய நேரம்!';

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count குறிப்புகள்',
      one: '1 குறிப்பு',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get newNote => 'புதிய குறிப்பு';

  @override
  String get newTransaction => 'புதிய பரிவர்த்தனை';

  @override
  String get search => 'தேடு';

  @override
  String get save => 'சேமி';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get delete => 'நீக்கு';

  @override
  String get lockedNote => 'பூட்டிய குறிப்பு';

  @override
  String get appLocked => 'செயலி பூட்டப்பட்டுள்ளது';

  @override
  String get unlock => 'திற';
}
