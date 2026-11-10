import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteContentProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'தனியுரிமைக் கொள்கை' : 'Privacy Policy'),
      ),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (site) {
          final text = (isTamil && site.privacyPolicyTa.isNotEmpty)
              ? site.privacyPolicyTa
              : (site.privacyPolicy.isNotEmpty
                  ? site.privacyPolicy
                  : 'Airo Techhub privacy policy:\n\nThis policy explains what Airo Techhub stores when you use the public site, the staff workspace, and the member portal.\n\n1. Workspace & Student Data\nWe store the records necessary to provide class rosters, scheduled sessions, and learning materials.\n\n2. Security\nAll credentials and session tokens are encrypted and transmitted securely.');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          );
        },
      ),
    );
  }
}

class CookiePolicyScreen extends ConsumerWidget {
  const CookiePolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteContentProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'குக்கீ கொள்கை' : 'Cookie Policy'),
      ),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (site) {
          final text = (isTamil && site.cookiePolicyTa.isNotEmpty)
              ? site.cookiePolicyTa
              : (site.cookiePolicy.isNotEmpty
                  ? site.cookiePolicy
                  : 'Airo Techhub cookie and browser storage policy:\n\nThis site and mobile application store session tokens and language preferences locally on your device to ensure smooth authentication and offline persistence.');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          );
        },
      ),
    );
  }
}

