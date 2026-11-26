import 'package:flutter_test/flutter_test.dart';
import 'package:invetory_system/admin/core/localization/admin_localizations.dart';

void main() {
  group('admin language selection', () {
    test('normalizes unsupported codes to English', () {
      expect(normalizeAdminLanguage('fr'), 'en');
      expect(normalizeAdminLanguage(null), 'en');
    });

    test('selects exactly one segment for each supported code', () {
      for (final language in supportedAdminLanguages) {
        final selected = supportedAdminLanguages
            .where((option) => isAdminLanguageSelected(language, option))
            .toList();
        expect(selected, [language]);
      }
    });

    test('admin labels render in English, Tamil, and Sinhala', () {
      const translations = {
        'en': 'Create Member',
        'ta': 'உறுப்பினரை உருவாக்கு',
        'si': 'සාමාජිකයෙකු සාදන්න',
      };

      for (final entry in translations.entries) {
        expect(
          adminUiText(
            entry.key,
            english: translations['en']!,
            tamil: translations['ta']!,
            sinhala: translations['si']!,
          ),
          entry.value,
        );
      }
    });
  });
}
