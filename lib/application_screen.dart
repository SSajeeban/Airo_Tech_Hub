import 'package:material_ui/material_ui.dart';

import 'home_shell.dart';
import 'mock_data.dart';
import 'app_logo.dart';
import 'portal_screen.dart';
import 'phone_sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationScreen extends StatefulWidget {
  final Member member;

  const ApplicationScreen({super.key, required this.member});

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  Group? _selected;

  bool _isSignOutHovered = false;

  // Sign out confirmation
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2A5A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF1B9A85)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B9A85),
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('signed_in_phone');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PortalScreen(memberPage: PhoneSignInScreen()),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);

    final groups = MockDb.groupsForMember(widget.member);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [AppBarLogo()],
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose an application',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 20),

                  for (final g in groups)
                    Card(
                      color: _selected?.id == g.id
                          ? teal.withValues(alpha: 0.12)
                          : null,
                      child: ListTile(
                        title: Text(g.name),
                        subtitle: Text(g.teacher),
                        onTap: () {
                          setState(() {
                            _selected = g;
                          });
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Continue button
                  FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomeShell(
                                  member: widget.member,
                                  group: _selected!,
                                ),
                              ),
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('CONTINUE'),
                  ),

                  const SizedBox(height: 8),

                  // Sign out text link below Continue
                  Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) {
                        setState(() {
                          _isSignOutHovered = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _isSignOutHovered = false;
                        });
                      },
                      child: TextButton(
                        onPressed: _signOut,
                        style: TextButton.styleFrom(
                          overlayColor: Colors.transparent,
                          foregroundColor: _isSignOutHovered
                              ? teal
                              : Colors.black54,
                        ),
                        child: Text(
                          'Sign out',
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: _isSignOutHovered
                                ? teal
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} Airo Techhub',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
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
