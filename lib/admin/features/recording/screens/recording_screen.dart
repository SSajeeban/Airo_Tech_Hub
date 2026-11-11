import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  final _titleController = TextEditingController();
  final Set<_RecordingSource> _selectedSources = {};
  _RecordingDestination _destination = _RecordingDestination.cloud;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _toggleSource(_RecordingSource source) {
    setState(() {
      if (!_selectedSources.add(source)) {
        _selectedSources.remove(source);
      }
    });
  }

  void _startRecording(bool isTamil) {
    final message = isTamil
        ? 'பதிவைப் தொடங்குவதற்கு கேமரா மற்றும் திரைப் பதிவு ஆதரவு தேவை.'
        : 'Recording capture is not set up yet. Camera and screen capture support must be connected first.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final preview = _buildPreview(context, isTamil);
        final settings = _buildSettings(context, isTamil, colorScheme);

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 24 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: preview),
                        const SizedBox(width: 24),
                        SizedBox(width: 320, child: settings),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [preview, const SizedBox(height: 16), settings],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview(BuildContext context, bool isTamil) {
    final selected = _selectedSources.isNotEmpty;
    final message = selected
        ? (isTamil
              ? 'தேர்ந்தெடுத்த உள்ளடக்கம் பதிவு முன்னோட்டத்தில் தோன்றும்.'
              : 'Your selected content will appear in the recording preview.')
        : (isTamil
              ? 'கேமராவை இயக்கவும், திரையைப் பகிரவும் அல்லது வெள்ளைப்பலகையைத் திறக்கவும்.'
              : 'Turn on the camera, share your screen, or open the whiteboard.');

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: Image.asset(
                'assets/images/logo.png',
                height: 30,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, color: AppColors.accent, size: 30),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFADB5C2),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    bool isTamil,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isTamil ? 'பதிவுகள்' : 'Recording',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isTamil
                  ? 'கேமரா, திரை, வெள்ளைப்பலகை அல்லது அனைத்தையும் ஒன்றாகப் பதிவு செய்யுங்கள்.'
                  : 'Record on your own with the camera, your screen, the whiteboard, or all of them together.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isTamil ? 'தலைப்பு' : 'Title',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isTamil ? 'பாடத் தலைப்பு' : 'Lesson title',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel(
              context,
              colorScheme,
              isTamil
                  ? 'இந்தப் பதிவை எங்கே சேமிக்க வேண்டும்?'
                  : 'Where should this recording be saved?',
            ),
            const SizedBox(height: 8),
            _ChoiceCard(
              title: isTamil ? 'மேகம்' : 'Cloud',
              subtitle: isTamil ? 'நூலகம் → பதிவுகள்' : 'Library → Recordings',
              selected: _destination == _RecordingDestination.cloud,
              onTap: () =>
                  setState(() => _destination = _RecordingDestination.cloud),
            ),
            const SizedBox(height: 8),
            _ChoiceCard(
              title: isTamil ? 'இந்தச் சாதனம்' : 'This device',
              subtitle: isTamil
                  ? 'வீடியோ கோப்பைப் பதிவிறக்கவும்'
                  : 'Download the video file',
              selected: _destination == _RecordingDestination.device,
              onTap: () =>
                  setState(() => _destination = _RecordingDestination.device),
            ),
            const SizedBox(height: 18),
            _sectionLabel(
              context,
              colorScheme,
              isTamil ? 'எதைப் பதிவு செய்ய வேண்டும்?' : 'What to record',
            ),
            const SizedBox(height: 8),
            _SourceCard(
              icon: Icons.videocam_outlined,
              title: isTamil ? 'கேமரா' : 'Camera',
              subtitle: isTamil ? 'உங்கள் வீடியோ' : 'Your video',
              selected: _selectedSources.contains(_RecordingSource.camera),
              onTap: () => _toggleSource(_RecordingSource.camera),
            ),
            const SizedBox(height: 8),
            _SourceCard(
              icon: Icons.screen_share_outlined,
              title: isTamil ? 'திரை' : 'Screen',
              subtitle: isTamil
                  ? 'திரை அல்லது சாளரத்தைத் தேர்ந்தெடுக்கவும்.'
                  : 'Choose a screen or window. It opens here.',
              selected: _selectedSources.contains(_RecordingSource.screen),
              onTap: () => _toggleSource(_RecordingSource.screen),
            ),
            const SizedBox(height: 8),
            _SourceCard(
              icon: Icons.draw_outlined,
              title: isTamil ? 'வெள்ளைப்பலகை' : 'Whiteboard',
              subtitle: isTamil
                  ? 'படத்தின் மீது வரையுங்கள்'
                  : 'Draw on the picture',
              selected: _selectedSources.contains(_RecordingSource.whiteboard),
              onTap: () => _toggleSource(_RecordingSource.whiteboard),
            ),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'திரைப் பகிர்வு உங்கள் சாதனம் அல்லது உலாவியைப் பொறுத்தது.'
                  : 'Screen sharing depends on the phone or browser.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _startRecording(isTamil),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isTamil ? 'பதிவைத் தொடங்கு' : 'Start recording'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
  ) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
  );
}

enum _RecordingDestination { cloud, device }

enum _RecordingSource { camera, screen, whiteboard }

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _OptionCard(
    title: title,
    subtitle: subtitle,
    selected: selected,
    onTap: onTap,
  );
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _OptionCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    selected: selected,
    onTap: onTap,
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData? icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? AppColors.accent
        : colorScheme.outlineVariant;

    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.14)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.accent,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
