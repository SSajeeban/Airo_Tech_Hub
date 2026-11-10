import 'package:flutter/material.dart';

import 'application_screen.dart';
import 'mock_data.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: navy,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/images/logo.png', height: 70),
                      const SizedBox(height: 24),
                      const Text(
                        'Sign in with your phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_codeSent) ...[
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const Text(
                          'If this number is registered, a code was sent.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _verify,
                          style: FilledButton.styleFrom(
                            backgroundColor: teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('VERIFY'),
                        ),
                      ] else
                        FilledButton(
                          onPressed: _sendCode,
                          style: FilledButton.styleFrom(
                            backgroundColor: teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Send code'),
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
