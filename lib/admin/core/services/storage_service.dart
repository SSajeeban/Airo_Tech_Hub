import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_session.dart';

class StorageService {
  static const String _keyToken = 'airotech_token';
  static const String _keyUser = 'airotech_user';
  static const String _keyLanguage = 'airotech_language';
  static const String _keyTheme = 'airotech_theme';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Session
  Future<void> saveSession(UserSession session) async {
    await _prefs.setString(_keyToken, session.token);
    await _prefs.setString(_keyUser, jsonEncode(session.user.toJson()));
  }

  UserSession? getSession() {
    final token = _prefs.getString(_keyToken);
    final userJson = _prefs.getString(_keyUser);
    if (token != null && userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return UserSession(
          token: token,
          user: UserProfile.fromJson(map),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
  }

  // Language: 'en' or 'ta'
  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'en';
  Future<void> setLanguage(String lang) => _prefs.setString(_keyLanguage, lang);

  // Theme: 'system', 'light', 'dark'
  String getThemeMode() => _prefs.getString(_keyTheme) ?? 'system';
  Future<void> setThemeMode(String theme) => _prefs.setString(_keyTheme, theme);
}

