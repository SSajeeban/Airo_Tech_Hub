import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import 'ai_teacher_screen.dart';

class AiTeacherEntry extends StatefulWidget {
  final VoidCallback onExit;

  const AiTeacherEntry({super.key, required this.onExit});

  @override
  State<AiTeacherEntry> createState() => _AiTeacherEntryState();
}

class _AiTeacherEntryState extends State<AiTeacherEntry> {
  late final Future<StorageService> _storage = StorageService.init();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorageService>(
      future: _storage,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: widget.onExit,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not initialize AI assistant: ${snapshot.error}',
                ),
              ),
            ),
          );
        }

        final storage = snapshot.data;
        if (storage == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: _AiTeacherWorkspace(onExit: widget.onExit),
        );
      },
    );
  }
}

class _AiTeacherWorkspace extends ConsumerWidget {
  final VoidCallback onExit;

  const _AiTeacherWorkspace({required this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final isTamil = language == 'ta';
    final isSinhala = language == 'si';
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final theme = isDark
        ? AppTheme.darkTheme(isTamil: isTamil, isSinhala: isSinhala)
        : AppTheme.lightTheme(isTamil: isTamil, isSinhala: isSinhala);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: onExit,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            adminUiText(
              language,
              english: 'AI Teacher',
              tamil: 'AI ஆசிரியர்',
              sinhala: 'AI ගුරුවරයා',
            ),
          ),
        ),
        body: const AiTeacherScreen(),
      ),
    );
  }
}
