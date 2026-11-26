import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';

class GroupJoinScreen extends ConsumerStatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  ConsumerState<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends ConsumerState<GroupJoinScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleJoin(String language) {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Prompt student to enter details or sign in
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  adminUiText(
                    language,
                    english: 'Group Found!',
                    tamil: 'குழு கண்டறியப்பட்டது!',
                    sinhala: 'කණ්ඩායම හමු විය!',
                  ),
                ),
              ],
            ),
            content: Text(
              adminUiText(
                language,
                english:
                    'Invited to: Cohort [$code]. Please sign in or register as a student to confirm your enrollment.',
                tamil:
                    'அழைப்பு: குழு [$code]. உங்கள் சேர்க்கையை உறுதிப்படுத்த மாணவராக உள்நுழையவும் அல்லது பதிவு செய்யவும்.',
                sinhala:
                    'ආරාධනා කර ඇත්තේ: කණ්ඩායම [$code]. ඔබගේ ලියාපදිංචිය තහවුරු කිරීමට ශිෂ්‍යයෙකු ලෙස පුරනය වන්න හෝ ලියාපදිංචි වන්න.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
                child: Text(
                  adminUiText(
                    language,
                    english: 'Continue to Sign In',
                    tamil: 'உள்நுழைவுக்குத் தொடரவும்',
                    sinhala: 'පුරනය වීමට ඉදිරියට යන්න',
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminUiText(
            language,
            english: 'Join Your Group',
            tamil: 'குழுவில் சேரவும்',
            sinhala: 'ඔබගේ කණ්ඩායමට එක්වන්න',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_scanner, size: 56, color: AppColors.brandBlue),
            ),
            const SizedBox(height: 24),
            Text(
              adminUiText(
                language,
                english: 'Enter Group or Class Code',
                tamil: 'குழு குறியீட்டை உள்ளிடவும்',
                sinhala: 'කණ්ඩායම් හෝ පන්ති කේතය ඇතුළත් කරන්න',
              ),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              adminUiText(
                language,
                english:
                    'Enter the invite code given by your teacher or institution admin.',
                tamil:
                    'உங்கள் ஆசிரியர் அல்லது குழு நிர்வாகி கொடுத்த 6-எழுத்து குறியீட்டை உள்ளிடவும்.',
                sinhala:
                    'ඔබගේ ගුරුවරයා හෝ ආයතන පරිපාලකයා ලබා දුන් ආරාධනා කේතය ඇතුළත් කරන්න.',
              ),
              style: TextStyle(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. MATH26',
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleJoin(language),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandBlue),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      adminUiText(
                        language,
                        english: 'Submit Code',
                        tamil: 'குழுவில் சேரவும்',
                        sinhala: 'කේතය ඉදිරිපත් කරන්න',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

