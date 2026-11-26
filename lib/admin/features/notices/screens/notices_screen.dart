import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  final _englishController = TextEditingController();
  final _tamilController = TextEditingController();
  final _sinhalaController = TextEditingController();
  late DateTime _expiresAt;
  String _selectedAudience = 'All groups';
  String _composeLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _englishController.dispose();
    _tamilController.dispose();
    _sinhalaController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _expiresAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _postNotice() {
    final english = _englishController.text.trim();
    final tamil = _tamilController.text.trim();
    final sinhala = _sinhalaController.text.trim();
    if (english.isEmpty && tamil.isEmpty && sinhala.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminUiText(
              _composeLanguage,
              english: 'Enter a notice message before posting.',
              tamil: 'வெளியிடுவதற்கு முன் அறிவிப்பு செய்தியை உள்ளிடவும்.',
              sinhala: 'පළ කිරීමට පෙර නිවේදන පණිවිඩයක් ඇතුළත් කරන්න.',
            ),
          ),
        ),
      );
      return;
    }

    final englishText = english.isEmpty ? tamil : english;
    final tamilText = tamil.isEmpty ? english : tamil;
    final sinhalaText = sinhala;
    final session = ref.read(sessionProvider);
    final author = session?.user.displayName.trim().isNotEmpty == true
        ? session!.user.displayName
        : 'Administrator';
    final notice = NoticeModel(
      id: 'not_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleFrom(englishText),
      titleTa: _titleFrom(tamilText),
      titleSi: _titleFrom(sinhalaText),
      content: englishText,
      contentTa: tamilText,
      contentSi: sinhalaText,
      isPinned: false,
      publishedAt: DateTime.now(),
      author: author,
      audience: _selectedAudience,
      expiresAt: _expiresAt,
    );

    ref
        .read(noticesProvider.notifier)
        .update((notices) => [notice, ...notices]);
    _englishController.clear();
    _tamilController.clear();
    _sinhalaController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adminUiText(
            _composeLanguage,
            english: 'Notice posted successfully.',
            tamil: 'அறிவிப்பு வெற்றிகரமாக வெளியிடப்பட்டது.',
            sinhala: 'නිවේදනය සාර්ථකව පළ කරන ලදී.',
          ),
        ),
      ),
    );
  }

  String _titleFrom(String message) {
    final firstLine = message.split('\n').first.trim();
    if (firstLine.length <= 56) return firstLine;
    return '${firstLine.substring(0, 53).trimRight()}...';
  }

  @override
  Widget build(BuildContext context) {
    final notices = ref.watch(noticesProvider);
    final groups = ref.watch(groupsProvider);
    final language = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleNotices = notices
        .where(
          (notice) =>
              notice.expiresAt == null ||
              notice.expiresAt!.isAfter(DateTime.now()),
        )
        .toList();
    final audienceOptions = [
      'All groups',
      ...groups.map((group) => group.name),
    ];
    if (!audienceOptions.contains(_selectedAudience)) {
      _selectedAudience = 'All groups';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminUiText(
            language,
            english: 'Notices',
            tamil: 'அறிவிப்புகள்',
            sinhala: 'දැනුම්දීම්',
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 420 ? 16.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      adminUiText(
                        language,
                        english: 'Notice board',
                        tamil: 'அறிவிப்பு பலகை',
                        sinhala: 'නිවේදන පුවරුව',
                      ),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: isDark
                                ? AppColors.headingDark
                                : AppColors.headingLight,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildComposer(
                      context,
                      language: language,
                      isDark: isDark,
                      audienceOptions: audienceOptions,
                    ),
                    const SizedBox(height: 18),
                    if (visibleNotices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          adminUiText(
                            language,
                            english: 'No notices yet.',
                            tamil: 'இன்னும் அறிவிப்புகள் இல்லை.',
                            sinhala: 'තවමත් නිවේදන නැත.',
                          ),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                          ),
                        ),
                      )
                    else
                      ...visibleNotices.map(
                        (notice) => _buildNoticeCard(
                          context,
                          notice,
                          language: language,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context, {
    required String language,
    required bool isDark,
    required List<String> audienceOptions,
  }) {
    final outlineColor = isDark ? AppColors.lineDark : AppColors.lineLight;
    final messageController = switch (_composeLanguage) {
      'ta' => _tamilController,
      'si' => _sinhalaController,
      _ => _englishController,
    };

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    adminUiText(
                      language,
                      english: 'Message',
                      tamil: 'செய்தி',
                      sinhala: 'පණිවිඩය',
                    ),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.mutedDark
                          : AppColors.mutedLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildLanguageButton(
                  label: 'EN',
                  selected: _composeLanguage == 'en',
                  isDark: isDark,
                  onPressed: () => setState(() => _composeLanguage = 'en'),
                ),
                const SizedBox(width: 6),
                _buildLanguageButton(
                  label: 'த',
                  selected: _composeLanguage == 'ta',
                  isDark: isDark,
                  onPressed: () => setState(() => _composeLanguage = 'ta'),
                ),
                const SizedBox(width: 6),
                _buildLanguageButton(
                  label: 'සි',
                  selected: _composeLanguage == 'si',
                  isDark: isDark,
                  onPressed: () => setState(() => _composeLanguage = 'si'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              minLines: 5,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: adminUiText(
                  _composeLanguage,
                  english: 'Type in English',
                  tamil: 'தமிழில் உள்ளிடவும்',
                  sinhala: 'සිංහලෙන් ඇතුළත් කරන්න',
                ),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: outlineColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildFieldLabel(
              adminUiText(
                language,
                english: 'Who can see this',
                tamil: 'யார் பார்க்கலாம்',
                sinhala: 'මෙය දැකිය හැක්කේ කාටද?',
              ),
              isDark,
            ),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              initialValue: _selectedAudience,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: audienceOptions
                  .map(
                    (audience) => DropdownMenuItem(
                      value: audience,
                      child: Text(
                        audience == 'All groups'
                            ? adminUiText(
                                language,
                                english: 'All groups',
                                tamil: 'அனைத்து குழுக்களும்',
                                sinhala: 'සියලුම කණ්ඩායම්',
                              )
                            : audience,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (audience) {
                if (audience != null) {
                  setState(() => _selectedAudience = audience);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildFieldLabel(
              adminUiText(
                language,
                english: 'Expires',
                tamil: 'காலாவதி',
                sinhala: 'කල් ඉකුත් වීම',
              ),
              isDark,
            ),
            const SizedBox(height: 5),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _selectExpiry,
              child: InputDecorator(
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy  h:mm a').format(_expiresAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _postNotice,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  adminUiText(
                    language,
                    english: 'Post notice',
                    tamil: 'வெளியிடு',
                    sinhala: 'නිවේදනය පළ කරන්න',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: selected ? AppColors.accent : Colors.transparent,
        foregroundColor: selected
            ? Colors.white
            : (isDark ? AppColors.inkDark : AppColors.inkLight),
        side: BorderSide(
          color: selected
              ? AppColors.accent
              : (isDark ? AppColors.lineDark : AppColors.lineLight),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildNoticeCard(
    BuildContext context,
    NoticeModel notice, {
    required String language,
    required bool isDark,
  }) {
    final content = language == 'ta'
        ? (notice.contentTa.isNotEmpty ? notice.contentTa : notice.content)
        : language == 'si'
        ? (notice.contentSi.isNotEmpty ? notice.contentSi : notice.content)
        : (notice.content.isNotEmpty ? notice.content : notice.contentTa);
    final title = language == 'ta'
        ? (notice.titleTa.isNotEmpty ? notice.titleTa : notice.title)
        : language == 'si'
        ? (notice.titleSi.isNotEmpty ? notice.titleSi : notice.title)
        : (notice.title.isNotEmpty ? notice.title : notice.titleTa);
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isPinned) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      adminUiText(
                        language,
                        english: 'PINNED',
                        tamil: 'முன்னிலை',
                        sinhala: 'ඉහළින් තබා ඇත',
                      ),
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    notice.author,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(notice.publishedAt),
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: TextStyle(
                color: isDark ? AppColors.inkDark : AppColors.inkLight,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.groups_2_outlined,
                  size: 15,
                  color: AppColors.mutedLight,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    notice.audience == 'All groups'
                        ? adminUiText(
                            language,
                            english: 'All groups',
                            tamil: 'அனைத்து குழுக்களும்',
                            sinhala: 'සියලුම කණ්ඩායම්',
                          )
                        : notice.audience,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
                if (notice.expiresAt != null)
                  Text(
                    '${adminUiText(language, english: 'Expires', tamil: 'காலாவதி', sinhala: 'කල් ඉකුත් වීම')} ${DateFormat('dd MMM').format(notice.expiresAt!)}',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
