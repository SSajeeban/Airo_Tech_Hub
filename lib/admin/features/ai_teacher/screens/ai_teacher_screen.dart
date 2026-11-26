import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class AiTeacherScreen extends ConsumerStatefulWidget {
  const AiTeacherScreen({super.key});

  @override
  ConsumerState<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends ConsumerState<AiTeacherScreen> {
  final _subjectController = TextEditingController();
  final _gradeController = TextEditingController();
  final _topicController = TextEditingController();
  final _questionController = TextEditingController();
  final _questionCountController = TextEditingController(text: '10');
  String _taskType = 'question';
  String? _responseLanguage;
  bool _isLoading = false;
  String? _generatedResult;

  @override
  void dispose() {
    _subjectController.dispose();
    _gradeController.dispose();
    _topicController.dispose();
    _questionController.dispose();
    _questionCountController.dispose();
    super.dispose();
  }

  String _requestPrompt() {
    switch (_taskType) {
      case 'exam':
        return [
          'Create an exam paper.',
          'Subject: ${_subjectController.text.trim()}',
          'Grade: ${_gradeController.text.trim()}',
          'Topic: ${_topicController.text.trim()}',
          'Number of questions: ${_questionCountController.text.trim()}',
        ].join('\n');
      case 'notes':
        return [
          'Create study notes.',
          'Subject: ${_subjectController.text.trim()}',
          'Grade: ${_gradeController.text.trim()}',
          'Topic: ${_topicController.text.trim()}',
        ].join('\n');
      default:
        return _questionController.text.trim();
    }
  }

  Future<void> _handleGenerate(String uiLanguage) async {
    final prompt = _requestPrompt();
    if ((_taskType == 'question' && _questionController.text.trim().isEmpty) ||
        (_taskType != 'question' &&
            (_subjectController.text.trim().isEmpty ||
                _topicController.text.trim().isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminUiText(
              uiLanguage,
              english: 'Please complete the required fields before continuing.',
              tamil: 'தொடர்வதற்கு தேவையான புலங்களை நிரப்பவும்.',
              sinhala: 'ඉදිරියට යාමට අවශ්‍ය ක්ෂේත්‍ර පුරවන්න.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedResult = null;
    });

    try {
      final answer = await ref
          .read(apiClientProvider)
          .askAiTeacher(
            prompt: prompt,
            taskType: _taskType,
            language: _responseLanguage ?? normalizeAdminLanguage(uiLanguage),
          );
      if (mounted) setState(() => _generatedResult = answer);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminUiText(
                uiLanguage,
                english: 'Could not get a response from AI Teacher: $error',
                tamil: 'AI ஆசிரியரிடமிருந்து பதிலைப் பெற முடியவில்லை: $error',
                sinhala: 'AI ගුරුවරයාගෙන් ප්‍රතිචාරයක් ලබාගත නොහැකි විය: $error',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveToLibrary(String language) {
    final result = _generatedResult;
    if (result == null) return;
    final topic = _taskType == 'question'
        ? _questionController.text.trim()
        : _topicController.text.trim();
    final safeTopic = topic.isEmpty
        ? 'AI ${_taskType == 'exam' ? 'Exam' : 'Notes'}'
        : topic.substring(0, topic.length > 40 ? 40 : topic.length);
    final title = '$safeTopic.txt';
    final newItem = LibraryItem(
      id: 'lib_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      folder: 'AI Teacher',
      fileType: 'TXT',
      size: '${(result.length / 1024).ceil()} KB',
      uploadedAt: DateTime.now(),
    );
    ref
        .read(libraryItemsProvider.notifier)
        .update((items) => [newItem, ...items]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adminUiText(
            language,
            english: 'Saved as a text file in Library: $title',
            tamil: 'நூலகத்தில் உரையாகச் சேமிக்கப்பட்டது: $title',
            sinhala: 'පුස්තකාලයේ පෙළ ගොනුවක් ලෙස සුරකින ලදී: $title',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminUiText(
                            language,
                            english: 'AI Teacher',
                            tamil: 'AI ஆசிரியர்',
                            sinhala: 'AI ගුරුවරයා',
                          ),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminUiText(
                            language,
                            english: 'Ask a question, or create an exam paper or notes. Generated text can be saved to your Library.',
                            tamil: 'கேள்வி கேளுங்கள், தேர்வுத் தாள் அல்லது குறிப்புகளை உருவாக்குங்கள். உருவாக்கிய உள்ளடக்கத்தை நூலகத்தில் உரையாகச் சேமிக்கலாம்.',
                            sinhala: 'ප්‍රශ්නයක් අසන්න, විභාග ප්‍රශ්න පත්‍රයක් හෝ සටහන් සාදන්න. සාදන ලද පෙළ පුස්තකාලයේ සුරැකිය හැක.',
                          ),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width > 650)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 2),
                      child: Text(
                        adminUiText(
                          language,
                          english: 'Token usage is managed by your account',
                          tamil: 'டோக்கன் பயன்பாடு கணக்கு அமைப்புகளால் நிர்வகிக்கப்படுகிறது',
                          sinhala: 'ඔබගේ ගිණුම මඟින් ටෝකන් භාවිතය කළමනාකරණය වේ',
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _buildModeSelector(language),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildForm(language),
                      const SizedBox(height: 14),
                      _buildResponseLanguageSelector(language),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleGenerate(language),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_submitLabel(language)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_generatedResult != null) ...[
                const SizedBox(height: 20),
                _buildResult(language, colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(String language) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _modeButton('question', adminUiText(language, english: 'Ask', tamil: 'கேள்', sinhala: 'අසන්න')),
        _modeButton('exam', adminUiText(language, english: 'Exam paper', tamil: 'தேர்வுத் தாள்', sinhala: 'විභාග ප්‍රශ්න පත්‍රය')),
        _modeButton('notes', adminUiText(language, english: 'Notes', tamil: 'குறிப்புகள்', sinhala: 'සටහන්')),
      ],
    );
  }

  Widget _buildResponseLanguageSelector(String language) {
    final selectedLanguage =
        _responseLanguage ?? normalizeAdminLanguage(language);
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          adminUiText(language, english: 'Response language:', tamil: 'பதில் மொழி:', sinhala: 'ප්‍රතිචාර භාෂාව:'),
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        for (final option in [
          ('en', adminUiText(language, english: 'English', tamil: 'ஆங்கிலம்', sinhala: 'ඉංග්‍රීසි')),
          ('ta', adminUiText(language, english: 'Tamil', tamil: 'தமிழ்', sinhala: 'දෙමළ')),
          ('si', adminUiText(language, english: 'Sinhala', tamil: 'சிங்களம்', sinhala: 'සිංහල')),
        ])
          ChoiceChip(
            label: Text(option.$2),
            selected: selectedLanguage == option.$1,
            showCheckmark: false,
            selectedColor: AppColors.accent,
            backgroundColor: colors.surface,
            side: BorderSide(
              color: selectedLanguage == option.$1
                  ? AppColors.accent
                  : colors.outlineVariant,
            ),
            labelStyle: TextStyle(
              color: selectedLanguage == option.$1
                  ? Colors.white
                  : colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
            onSelected: (_) => setState(() {
              _responseLanguage = option.$1;
            }),
          ),
      ],
    );
  }

  Widget _modeButton(String type, String label) {
    final selected = _taskType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.accent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: selected
            ? AppColors.accent
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) => setState(() {
        _taskType = type;
        _generatedResult = null;
      }),
    );
  }

  Widget _buildForm(String language) {
    if (_taskType == 'question') return _buildQuestionForm(language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final subjectField = _labeledField(
              adminUiText(language, english: 'Subject', tamil: 'பாடம்', sinhala: 'විෂය'),
              _subjectController,
            );
            final gradeField = _labeledField(
              adminUiText(language, english: 'Grade', tamil: 'வகுப்பு', sinhala: 'ශ්‍රේණිය'),
              _gradeController,
            );
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  subjectField,
                  const SizedBox(height: 12),
                  gradeField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: subjectField),
                const SizedBox(width: 14),
                Expanded(child: gradeField),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _labeledField(adminUiText(language, english: 'Topic', tamil: 'தலைப்பு', sinhala: 'මාතෘකාව'), _topicController),
        if (_taskType == 'exam') ...[
          const SizedBox(height: 12),
          _labeledField(
            adminUiText(language, english: 'Questions', tamil: 'கேள்விகள்', sinhala: 'ප්‍රශ්න'),
            _questionCountController,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionForm(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _labeledField(
          adminUiText(language, english: 'Your question', tamil: 'உங்கள் கேள்வி', sinhala: 'ඔබගේ ප්‍රශ්නය'),
          _questionController,
          maxLines: 5,
          minLines: 3,
          hint: adminUiText(
            language,
            english: 'Ask about a lesson, a concept, or how to explain a topic.',
            tamil: 'உங்கள் பாடம் அல்லது கேள்வியை எழுதுங்கள்',
            sinhala: 'පාඩමක්, සංකල්පයක් හෝ මාතෘකාවක් පැහැදිලි කරන ආකාරය ගැන අසන්න.',
          ),
        ),
      ],
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  String _submitLabel(String language) {
    if (language == 'ta') {
      return switch (_taskType) {
        'exam' => 'தேர்வுத் தாளை உருவாக்கு',
        'notes' => 'குறிப்புகளை உருவாக்கு',
        _ => 'கேள்விக்கு பதிலளி',
      };
    }
    return switch (_taskType) {
      'exam' => language == 'si' ? 'විභාග ප්‍රශ්න පත්‍රය සාදන්න' : 'Create exam paper',
      'notes' => language == 'si' ? 'සටහන් සාදන්න' : 'Create notes',
      _ => language == 'si' ? 'AI ගුරුවරයාගෙන් අසන්න' : 'Ask AI Teacher',
    };
  }

  Widget _buildResult(String language, ColorScheme colors) {
    final result = _generatedResult!;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    adminUiText(language, english: 'AI Teacher response', tamil: 'AI ஆசிரியரின் பதில்', sinhala: 'AI ගුරුවරයාගේ ප්‍රතිචාරය'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: adminUiText(language, english: 'Copy response', tamil: 'நகலெடு', sinhala: 'ප්‍රතිචාරය පිටපත් කරන්න'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result));
                    _showMessage(
                      adminUiText(language, english: 'Response copied.', tamil: 'பதில் நகலெடுக்கப்பட்டது.', sinhala: 'ප්‍රතිචාරය පිටපත් කරන ලදී.'),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: adminUiText(language, english: 'Save to Library', tamil: 'நூலகத்தில் சேமி', sinhala: 'පුස්තකාලයට සුරකින්න'),
                  onPressed: () => _saveToLibrary(language),
                  icon: const Icon(
                    Icons.bookmark_add_outlined,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              result,
              style: TextStyle(color: colors.onSurface, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
