import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Crisp light background as in screenshot
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header: Breadcrumb (Left) & Language Toggle (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Breadcrumb: Home / Sign in
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).canPop()) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();
                                } else {
                                  context.go('/');
                                }
                              },
                              child: Text(
                                localText(
                                  english: 'Home',
                                  tamil: 'முகப்பு',
                                  sinhala: 'මුල් පිටුව',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const Text(
                              ' / ',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              localText(
                                english: 'Sign in',
                                tamil: 'உள்நுழையவும்',
                                sinhala: 'පිවිසෙන්න',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // Language Pill Switcher [ EN | த | සි ]
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Center Sign-In Card Container (Exact Template Match)
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Gradient Border Stripe (Blue to Teal/Green)
                              Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF116B9E),
                                      Color(0xFF169688),
                                      Color(0xFF36AC6C),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  32,
                                  28,
                                  36,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // AIRO TECHHUB Official Logo
                                      Center(
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          height: 64,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => Column(
                                            children: const [
                                              Icon(
                                                Icons.school_outlined,
                                                size: 48,
                                                color: Color(0xFF169688),
                                              ),
                                              Text(
                                                'AIRO TECHHUB',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 20,
                                                  letterSpacing: 2,
                                                  color: Color(0xFF116B9E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Subtitle: "Sign in with your email"
                                      Center(
                                        child: Text(
                                          localText(
                                            english: 'Sign in with your email',
                                            tamil: 'உங்கள் மின்னஞ்சல் மூலம் உள்நுழையவும்',
                                            sinhala: 'ඔබගේ විද්‍යුත් තැපෑලෙන් පිවිසෙන්න',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      // Error Message Display
                                      if (_errorMessage != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.dangerBg,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.danger,
                                            ),
                                          ),
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: AppColors.danger,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Email Field Label
                                      Text(
                                        localText(
                                          english: 'Email',
                                          tamil: 'மின்னஞ்சல்',
                                          sinhala: 'විද්‍යුත් තැපෑල',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Email Input (Soft Ice-Blue/Grey Fill)
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFEEF4FF)
                                              .withValues(alpha: 0.6),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF14877C),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null ||
                                              val.trim().isEmpty) {
                                            return localText(
                                              english:
                                                  'Please enter your email',
                                              tamil: 'மின்னஞ்சலை உள்ளிடவும்',
                                              sinhala: 'කරුණාකර විද්‍යුත් තැපෑල ඇතුළත් කරන්න',
                                            );
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 18),

                                      // Password Field Label
                                      Text(
                                        localText(
                                          english: 'Password',
                                          tamil: 'கடவுச்சொல்',
                                          sinhala: 'මුරපදය',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Password Input (Soft Ice-Blue/Grey Fill)
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFEEF4FF)
                                              .withValues(alpha: 0.6),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF14877C),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return localText(
                                              english:
                                                  'Please enter your password',
                                              tamil: 'கடவுச்சொல்லை உள்ளிடவும்',
                                              sinhala:
                                                  'කරුණාකර මුරපදය ඇතුළත් කරන්න',
                                            );
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 24),

                                      // SIGN IN Button (Exact Teal color #14877C and uppercase styling)
                                      SizedBox(
                                        height: 46,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF14877C,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
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

                                      // "New subscriber? Create an account"
                                      Center(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              localText(
                                                english: 'New subscriber? ',
                                                tamil: 'புதிய சந்தாதாரரா? ',
                                                sinhala: 'නව ග්‍රාහකයෙක්ද? ',
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 13,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  context.push('/register'),
                                              child: Text(
                                                localText(
                                                  english: 'Create an account',
                                                  tamil: 'கணக்கை உருவாக்கவும்',
                                                  sinhala: 'ගිණුමක් සාදන්න',
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFF14877C),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF11182F),
                              Color(0xFF18264D),
                              Color(0xFF24345B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF11182F)
                                  .withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localText(
                                english: 'AI Teacher',
                                tamil: 'AI ஆசிரியர்',
                                sinhala: 'AI ගුරුවරයා',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              localText(
                                english: 'Ask a question, get an exam, or write notes.',
                                tamil: 'எந்தக் கேள்வியையும் கேளுங்கள், தேர்வுக்கு படிக்கவும் அல்லது ஆய்வு செய்யவும்.',
                                sinhala: 'ප්‍රශ්නයක් විමසන්න, විභාගයක් සකසන්න හෝ සටහන් ලියන්න.',
                              ),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
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
