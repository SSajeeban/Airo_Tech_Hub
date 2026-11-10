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
  final _promptController = TextEditingController();
  String _taskType = 'question'; // 'question', 'exam', 'notes'
  bool _isLoading = false;
  String? _generatedResult;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedResult = null;
    });

    final currentLang = ref.read(languageProvider);
    final client = ref.read(apiClientProvider);

    try {
      final answer = await client.askAiTeacher(
        prompt: prompt,
        taskType: _taskType,
        language: currentLang,
      );
      if (mounted) {
        setState(() => _generatedResult = answer);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveToLibrary() {
    if (_generatedResult == null) return;
    final title = 'AI Generated - ${_promptController.text.trim().substring(0, _promptController.text.trim().length > 25 ? 25 : _promptController.text.trim().length)}.txt';
    final newItem = LibraryItem(
      id: 'lib_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      folder: 'AI Teacher Notes',
      fileType: 'TXT',
      size: '12 KB',
      uploadedAt: DateTime.now(),
    );
    ref.read(libraryItemsProvider.notifier).update((state) => [newItem, ...state]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to Library: $title')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isTamil = currentLang == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.brandGreen, size: 22),
            const SizedBox(width: 8),
            Text(isTamil ? 'AI ஆசிரியர்' : 'AI Teacher Assistant'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16233B) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'கேளுங்கள், தேர்வு அமையுங்கள், குறிப்பெழுதுங்கள்' : 'Ask questions, set exams, or draft notes',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTamil ? 'ஆங்கிலம் மற்றும் தமிழில் உடனடியாக பதிலளிக்கும்.' : 'Works fluently in both English & Tamil.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Mode Selector
            Text(
              isTamil ? 'பணி முறைமை:' : 'Select AI Mode:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildModeChoice('question', isTamil ? 'கேள்வி' : 'Ask Q&A', Icons.help_outline),
                const SizedBox(width: 8),
                _buildModeChoice('exam', isTamil ? 'தேர்வு' : 'Exam Paper', Icons.assignment_outlined),
                const SizedBox(width: 8),
                _buildModeChoice('notes', isTamil ? 'குறிப்புகள்' : 'Study Notes', Icons.menu_book_outlined),
              ],
            ),

            const SizedBox(height: 20),

            // Prompt Input
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isTamil
                    ? 'உங்கள் பாடம் அல்லது தலைப்பை உள்ளிடவும் (எ.கா. வகை நுண்கணிதம், நியூட்டனின் விதிகள்)...'
                    : 'Enter your subject topic or inquiry (e.g. Calculus Derivatives, Newton Laws of Motion)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(
                _isLoading
                    ? (isTamil ? 'உருவாக்குகிறது...' : 'Generating...')
                    : (isTamil ? 'AI மூலம் உருவாக்கு' : 'Generate with AI Teacher'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),

            if (_generatedResult != null) ...[
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTamil ? 'AI ஆசிரியரின் முடிவு:' : 'AI Teacher Response:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Copy text',
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedResult!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Response copied to clipboard!')),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Save to Library',
                        icon: const Icon(Icons.bookmark_add, color: AppColors.accent, size: 20),
                        onPressed: _saveToLibrary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.brandGreen, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    _generatedResult!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeChoice(String mode, String label, IconData icon) {
    final isSelected = _taskType == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _taskType = mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.brandGreen : AppColors.lineLight,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.mutedLight),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

