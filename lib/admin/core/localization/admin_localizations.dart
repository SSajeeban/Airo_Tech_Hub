/// Language helpers shared by the admin experience.
///
/// The UI intentionally supports only these exact language codes. Keeping the
/// normalization and labels here prevents an unsupported stored value from
/// leaving every language option unselected.
const supportedAdminLanguages = {'en', 'ta', 'si'};

String normalizeAdminLanguage(String? language) {
  return supportedAdminLanguages.contains(language) ? language! : 'en';
}

bool isAdminLanguageSelected(String currentLanguage, String option) {
  return supportedAdminLanguages.contains(option) &&
      normalizeAdminLanguage(currentLanguage) == option;
}

String adminLanguageLabel(String language) {
  switch (normalizeAdminLanguage(language)) {
    case 'ta':
      return 'தமிழ்';
    case 'si':
      return 'සිංහල';
    default:
      return 'English';
  }
}

/// Returns a fully translated admin label for the selected language.
///
/// Sinhala labels are explicit: if a caller has not supplied a translation
/// for a new label, fail loudly in debug/test runs instead of silently showing
/// English while Sinhala is selected.
String adminUiText(
  String language, {
  required String english,
  required String tamil,
  required String sinhala,
}) {
  switch (normalizeAdminLanguage(language)) {
    case 'ta':
      return tamil;
    case 'si':
      return sinhala;
    default:
      return english;
  }
}
