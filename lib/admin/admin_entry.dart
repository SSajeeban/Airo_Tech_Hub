import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/routes/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';

class AdminEntry extends StatefulWidget {
  const AdminEntry({super.key});

  @override
  State<AdminEntry> createState() => _AdminEntryState();
}

class _AdminEntryState extends State<AdminEntry> {
  late final Future<StorageService> _init = StorageService.init();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorageService>(
      future: _init,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(snap.data!)],
          child: const _AdminApp(),
        );
      },
    );
  }
}

class _AdminApp extends ConsumerWidget {
  const _AdminApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';

    return MaterialApp.router(
      title: 'AIRO TECHHUB Admin',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme(isTamil: isTamil),
      darkTheme: AppTheme.darkTheme(isTamil: isTamil),
      routerConfig: router,
    );
  }
}
