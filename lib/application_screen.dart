import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'mock_data.dart';
import 'app_logo.dart';

class ApplicationScreen extends StatefulWidget {
  final Member member;

  const ApplicationScreen({super.key, required this.member});

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  Group? _selected;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);
    final groups = MockDb.groupsForMember(widget.member);

    return Scaffold(
      appBar: AppBar(
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
                        onTap: () => setState(() => _selected = g),
                      ),
                    ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTemp extends StatelessWidget {
  final Member member;
  final Group group;

  const _HomeTemp({required this.member, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.name), actions: const [AppBarLogo()]),
      body: Center(
        child: Text(
          'Welcome, ${member.name}!\n(Home screen அடுத்த படியில்)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
