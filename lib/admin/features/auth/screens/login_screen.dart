import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'rasiksafran@gmail.com');
  final _passwordController = TextEditingController(text: '••••••••••');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openAiroWebsite() async {
    final uri = Uri.parse('https://airotechhub.lk/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(sessionProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text.trim());
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

  Widget _languageButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF14877C) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isTamil = currentLang == 'ta';
    final isSinhala = currentLang == 'si';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String localText({
      required String english,
      required String tamil,
      required String sinhala,
    }) {
      if (isTamil) return tamil;
      if (isSinhala) return sinhala;
      return english;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF17264A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: localText(
                            english: 'Back',
                            tamil: 'பின்னால்',
                            sinhala: 'ආපසු',
                          ),
                          onPressed: () {
                            if (Navigator.of(
                              context,
                              rootNavigator: true,
                            ).canPop()) {
                              Navigator.of(context, rootNavigator: true).pop();
                            } else {
                              context.go('/');
                            }
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF223653)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334A67)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Row(
                                children: [
                                  _languageButton(
                                    context,
                                    label: 'EN',
                                    selected: currentLang == 'en',
                                    onTap: () => ref
                                        .read(languageProvider.notifier)
                                        .setLanguage('en'),
                                  ),
                                  _languageButton(
                                    context,
                                    label: 'த',
                                    selected: isTamil,
                                    onTap: () => ref
                                        .read(languageProvider.notifier)
                                        .setLanguage('ta'),
                                  ),
                                  _languageButton(
                                    context,
                                    label: 'සි',
                                    selected: isSinhala,
                                    onTap: () => ref
                                        .read(languageProvider.notifier)
                                        .setLanguage('si'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: isDark
                                  ? localText(
                                      english: 'Light mode',
                                      tamil: 'வெளிச்ச பயன்முறை',
                                      sinhala: 'එළිය මාදිලිය',
                                    )
                                  : localText(
                                      english: 'Dark mode',
                                      tamil: 'இருள் பயன்முறை',
                                      sinhala: 'අඳුරු මාදිලිය',
                                    ),
                              onPressed: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setTheme(
                                    isDark ? ThemeMode.light : ThemeMode.dark,
                                  ),
                              icon: Icon(
                                isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Image.asset(
                                  isDark
                                      ? 'assets/images/logo_dark.png'
                                      : 'assets/images/logo.png',
                                  height: 76,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                localText(
                                  english: 'Sign in with your email',
                                  tamil: 'உங்கள் மின்னஞ்சல் மூலம் உள்நுழையவும்',
                                  sinhala: 'ඔබගේ විද්‍යුත් තැපෑලෙන් පිවිසෙන්න',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 28),
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF7F1D1D)
                                        : AppColors.dangerBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.danger),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Text(
                                localText(
                                  english: 'Email',
                                  tamil: 'மின்னஞ்சல்',
                                  sinhala: 'විද්‍යුත් තැපෑල',
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF263A5B)
                                      : const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF334A67)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF334A67)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF14877C),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return localText(
                                      english: 'Please enter your email',
                                      tamil: 'மின்னஞ்சலை உள்ளிடவும்',
                                      sinhala: 'කරුණාකර විද්‍යුත් තැපෑල ඇතුළත් කරන්න',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              Text(
                                localText(
                                  english: 'Password',
                                  tamil: 'கடவுச்சொல்',
                                  sinhala: 'මුරපදය',
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF263A5B)
                                      : const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF334A67)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF334A67)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF14877C),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return localText(
                                      english: 'Please enter your password',
                                      tamil: 'கடவுச்சொல்லை உள்ளிடவும்',
                                      sinhala: 'කරුණාකර මුරපදය ඇතුළත් කරන්න',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF14877C),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          localText(
                                            english: 'SIGN IN',
                                            tamil: 'உள்நுழைக',
                                            sinhala: 'පිවිසෙන්න',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Center(
                                child: TextButton(
                                  onPressed: _openAiroWebsite,
                                  child: Text(
                                    localText(
                                      english: 'Back to the site',
                                      tamil: 'தளத்திற்கு திரும்பு',
                                      sinhala: 'වෙබ් අඩවියට ආපසු',
                                    ),
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF9BD8CF)
                                          : const Color(0xFF14877C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text(
                                      localText(
                                        english: 'New subscriber? ',
                                        tamil: 'புதிய சந்தாதாரரா? ',
                                        sinhala: 'නව ග්‍රාහකයෙක්ද? ',
                                      ),
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFFCBD5E1)
                                            : const Color(0xFF64748B),
                                        fontSize: 13,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => context.push('/register'),
                                      child: Text(
                                        localText(
                                          english: 'Create an account',
                                          tamil: 'கணக்கை உருவாக்கவும்',
                                          sinhala: 'ගිණුමක් සාදන්න',
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFF14877C),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '© 2026 Airo Techhub',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
