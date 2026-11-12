import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'phone_sign_in_screen.dart';
import 'portal_screen.dart';

void main() {
  runApp(const AiroApp());
}

class AiroApp extends StatelessWidget {
  const AiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        title: 'Airo Techhub',
        debugShowCheckedModeBanner: false,
        themeMode: AppSettings.instance.themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B9A85)),
          scaffoldBackgroundColor: const Color(0xFFF8FAFB),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B9A85),
            brightness: Brightness.dark,
          ),
        ),
        home: const PortalScreen(memberPage: PhoneSignInScreen()),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinGroup() {
    final code = _codeController.text.trim();
    final message = code.length == 8
        ? 'Code: $code (இதை அடுத்த படிகளில் இணைப்போம்)'
        : 'Class code 8 எழுத்துகள் இருக்க வேண்டும்';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'AIRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  const Text(
                    'TECHHUB',
                    textAlign: TextAlign.center,
                    style: TextStyle(letterSpacing: 6, color: navy),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Join your teacher\'s class',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the code from your group admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 8,
                            decoration: InputDecoration(
                              labelText: 'Class code',
                              hintText: 'ABCD2345',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _joinGroup,
                            style: FilledButton.styleFrom(
                              backgroundColor: teal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Join your group'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Already in a class?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign in with your phone'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
