import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/admin_localizations.dart';
import '../../../core/providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(sessionProvider.notifier).register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        context.go('/app');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminUiText(
            language,
            english: 'Create Account',
            tamil: 'பதிவு செய்யுங்கள்',
            sinhala: 'ගිණුමක් සාදන්න',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                adminUiText(
                  language,
                  english: 'Register as a Subscriber',
                  tamil: 'சந்தாதாரர் பதிவு',
                  sinhala: 'දායකයෙකු ලෙස ලියාපදිංචි වන්න',
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                adminUiText(
                  language,
                  english:
                      'An admin assigns your plan before you open an application.',
                  tamil:
                      'ஒரு நிர்வாகி நீங்கள் விண்ணப்பத்தைத் திறப்பதற்கு முன் உங்கள் திட்டத்தை ஒதுக்குகிறார்.',
                  sinhala:
                      'ඔබ අයදුම්පත විවෘත කිරීමට පෙර පරිපාලකයෙකු ඔබට සැලසුමක් පවරයි.',
                ),
                style: TextStyle(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: adminUiText(
                    language,
                    english: 'Full Name',
                    tamil: 'முழுப் பெயர்',
                    sinhala: 'සම්පූර්ණ නම',
                  ),
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return adminUiText(
                      language,
                      english: 'Please enter your name',
                      tamil: 'பெயரை உள்ளிடவும்',
                      sinhala: 'කරුණාකර ඔබගේ නම ඇතුළත් කරන්න',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: adminUiText(
                    language,
                    english: 'Email',
                    tamil: 'மின்னஞ்சல்',
                    sinhala: 'විද්‍යුත් තැපෑල',
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return adminUiText(
                      language,
                      english: 'Please enter your email',
                      tamil: 'மின்னஞ்சலை உள்ளிடவும்',
                      sinhala: 'කරුණාකර ඔබගේ විද්‍යුත් තැපෑල ඇතුළත් කරන්න',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: adminUiText(
                    language,
                    english: 'Password',
                    tamil: 'கடவுச்சொல்',
                    sinhala: 'මුරපදය',
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.length < 6) {
                    return adminUiText(
                      language,
                      english: 'Password must be at least 6 characters',
                      tamil: 'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்',
                      sinhala: 'මුරපදය අවම වශයෙන් අක්ෂර 6ක් විය යුතුය',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        adminUiText(
                          language,
                          english: 'Create Account',
                          tamil: 'கணக்கை உருவாக்கவும்',
                          sinhala: 'ගිණුමක් සාදන්න',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    adminUiText(
                      language,
                      english: 'Already have an account? Sign In',
                      tamil: 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழையவும்',
                      sinhala: 'දැනටමත් ගිණුමක් තිබේද? පුරනය වන්න',
                    ),
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

