import 'package:material_ui/material_ui.dart';

import 'translations.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  String language = 'English';
  ThemeMode themeMode = ThemeMode.light;

  bool get isTamil => language == 'Tamil';
  bool get isSinhala => language == 'Sinhala';

  String get languageLabel {
    switch (language) {
      case 'Tamil':
        return 'த';
      case 'Sinhala':
        return 'සි';
      default:
        return 'EN';
    }
  }

  void setLanguage(String value) {
    if (!['English', 'Tamil', 'Sinhala'].contains(value)) return;

    if (language != value) {
      language = value;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    switch (language) {
      case 'English':
        setLanguage('Tamil');
        break;
      case 'Tamil':
        setLanguage('Sinhala');
        break;
      default:
        setLanguage('English');
    }
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  String tr(String english) {
    switch (language) {
      case 'Tamil':
        return tamilTexts[english] ?? english;
      case 'Sinhala':
        return sinhalaTexts[english] ?? english;
      default:
        return english;
    }
  }
}

String tr(String english) => AppSettings.instance.tr(english);
