import 'package:flutter/material.dart';
import 'translations.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  bool isTamil = false;
  ThemeMode themeMode = ThemeMode.light;

  void toggleLanguage() {
    isTamil = !isTamil;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  String tr(String english) {
    if (!isTamil) return english;
    return tamilTexts[english] ?? english;
  }
}

String tr(String english) => AppSettings.instance.tr(english);
