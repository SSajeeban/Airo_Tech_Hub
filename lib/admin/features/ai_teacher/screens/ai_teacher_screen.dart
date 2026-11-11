import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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

  Future<void> _handleGenerate(bool isTamil) async {
    final prompt = _requestPrompt();
    if ((_taskType == 'question' && _questionController.text.trim().isEmpty) ||
        (_taskType != 'question' &&
            (_subjectController.text.trim().isEmpty ||
                _topicController.text.trim().isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTamil
                ? 'தொடர்வதற்கு தேவையான புலங்களை நிரப்பவும்.'
                : 'Please complete the required fields before continuing.',
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
            language: _responseLanguage ?? (isTamil ? 'ta' : 'en'),
          );
      if (mounted) setState(() => _generatedResult = answer);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTamil
                  ? 'AI ஆசிரியரிடமிருந்து பதிலைப் பெற முடியவில்லை: $error'
                  : 'Could not get a response from AI Teacher: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveToLibrary(bool isTamil) {
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
          isTamil
              ? 'நூலகத்தில் உரையாகச் சேமிக்கப்பட்டது: $title'
              : 'Saved as a text file in Library: $title',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
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
                          isTamil ? 'AI ஆசிரியர்' : 'AI Teacher',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTamil
                              ? 'கேள்வி கேளுங்கள், தேர்வுத் தாள் அல்லது குறிப்புகளை உருவாக்குங்கள். உருவாக்கிய உள்ளடக்கத்தை நூலகத்தில் உரையாகச் சேமிக்கலாம்.'
                              : 'Ask a question, or create an exam paper or notes. Generated text can be saved to your Library.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width > 650)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 2),
                      child: Text(
                        isTamil
                            ? 'டோக்கன் பயன்பாடு கணக்கு அமைப்புகளால் நிர்வகிக்கப்படுகிறது'
                            : 'Token usage is managed by your account',
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
              _buildModeSelector(isTamil),
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
                      _buildForm(isTamil),
                      const SizedBox(height: 14),
                      _buildResponseLanguageSelector(isTamil),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleGenerate(isTamil),
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
                            : Text(_submitLabel(isTamil)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_generatedResult != null) ...[
                const SizedBox(height: 20),
                _buildResult(isTamil, colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(bool isTamil) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _modeButton('question', isTamil ? 'கேள்' : 'Ask'),
        _modeButton('exam', isTamil ? 'தேர்வுத் தாள்' : 'Exam paper'),
        _modeButton('notes', isTamil ? 'குறிப்புகள்' : 'Notes'),
      ],
    );
  }

  Widget _buildResponseLanguageSelector(bool isTamil) {
    final selectedLanguage = _responseLanguage ?? (isTamil ? 'ta' : 'en');
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          isTamil ? 'பதில் மொழி:' : 'Response language:',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        for (final option in [
          ('en', isTamil ? 'ஆங்கிலம்' : 'English'),
          ('ta', isTamil ? 'தமிழ்' : 'Tamil'),
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

  Widget _buildForm(bool isTamil) {
    if (_taskType == 'question') return _buildQuestionForm(isTamil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final subjectField = _labeledField(
              isTamil ? 'பாடம்' : 'Subject',
              _subjectController,
            );
            final gradeField = _labeledField(
              isTamil ? 'வகுப்பு' : 'Grade',
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
        _labeledField(isTamil ? 'தலைப்பு' : 'Topic', _topicController),
        if (_taskType == 'exam') ...[
          const SizedBox(height: 12),
          _labeledField(
            isTamil ? 'கேள்விகள்' : 'Questions',
            _questionCountController,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionForm(bool isTamil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _labeledField(
          isTamil ? 'உங்கள் கேள்வி' : 'Your question',
          _questionController,
          maxLines: 5,
          minLines: 3,
          hint: isTamil
              ? 'உங்கள் பாடம் அல்லது கேள்வியை எழுதுங்கள்'
              : 'Ask about a lesson, a concept, or how to explain a topic.',
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

  String _submitLabel(bool isTamil) {
    if (isTamil) {
      return switch (_taskType) {
        'exam' => 'தேர்வுத் தாளை உருவாக்கு',
        'notes' => 'குறிப்புகளை உருவாக்கு',
        _ => 'கேள்விக்கு பதிலளி',
      };
    }
    return switch (_taskType) {
      'exam' => 'Create exam paper',
      'notes' => 'Create notes',
      _ => 'Ask AI Teacher',
    };
  }

  Widget _buildResult(bool isTamil, ColorScheme colors) {
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
                    isTamil ? 'AI ஆசிரியரின் பதில்' : 'AI Teacher response',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isTamil ? 'நகலெடு' : 'Copy response',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result));
                    _showMessage(
                      isTamil ? 'பதில் நகலெடுக்கப்பட்டது.' : 'Response copied.',
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: isTamil ? 'நூலகத்தில் சேமி' : 'Save to Library',
                  onPressed: () => _saveToLibrary(isTamil),
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
