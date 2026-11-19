import 'package:material_ui/material_ui.dart';

import 'app_settings.dart';
import 'application_screen.dart';
import 'mock_data.dart';
import 'translations.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Enter your mobile number');
      return;
    }
    setState(() {
      _codeSent = true;
    });
    _showMessage('If this number is registered, a code was sent.');
  }

  void _verify() {
    final member = MockDb.findMemberByPhone(_phoneController.text.trim());
    final codeOk = _codeController.text.trim() == MockDb.testOtp;

    if (member != null && codeOk) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ApplicationScreen(member: member)),
      );
    } else {
      _showMessage('Invalid number or code');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(text))));
  }

  Widget _buildLanguageSelector(Color teal) {
    final currentLang = AppSettings.instance.language;

    Widget segment(String lang, String label) {
      final isSelected = currentLang == lang;
      return InkWell(
        onTap: () {
          AppSettings.instance.setLanguage(lang);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? teal : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment('English', 'EN'),
          const SizedBox(width: 2),
          segment('Tamil', 'த'),
          const SizedBox(width: 2),
          segment('Sinhala', 'සි'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Home link on left, Language switcher (EN, த, සි) on right
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).maybePop(),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Text(
                                  tr('Home'),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            _buildLanguageSelector(teal),
                          ],
                        ),
                      ),

                      // Center form content
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      height: 84,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    tr('Sign in with your phone'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    tr('Mobile number'),
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: '07XXXXXXXX',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: teal,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_codeSent) ...[
                                    const SizedBox(height: 18),
                                    Text(
                                      tr('Verification code'),
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _codeController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      decoration: InputDecoration(
                                        hintText: tr('Enter OTP'),
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: teal,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      tr('If this number is registered, a code was sent.'),
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton(
                                      onPressed:
                                          _codeSent ? _verify : _sendCode,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: teal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        _codeSent
                                            ? tr('VERIFY OTP')
                                            : tr('SEND OTP'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: teal,
                                    ),
                                    child: Text(tr('Back to the site')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Footer: "© 2026 Airo Techhub"
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 12),
                        child: Center(
                          child: Text(
                            '© 2026 Airo Techhub',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
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
      ),
    );
  }
}
