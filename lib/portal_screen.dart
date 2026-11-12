import 'package:flutter/material.dart';

import 'admin/admin_entry.dart';
import 'app_settings.dart';

class PortalScreen extends StatelessWidget {
  final Widget memberPage;

  const PortalScreen({super.key, required this.memberPage});

  void _openMember(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => memberPage));
  }

  void _notAvailable(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name portal is not available in this app yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navy = Theme.of(context).colorScheme.onSurface;

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
                  const SizedBox(height: 16),
                  Image.asset('assets/images/logo.png', height: 90),
                  const SizedBox(height: 32),
                  Text(
                    tr('SIGN IN TO A PORTAL'),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B9A85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('Choose your portal'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PortalCard(
                    tag: 'Students & members',
                    title: 'Member',
                    subtitle: 'Phone sign in',
                    description: 'Join your teacher\'s class, chat, meetings, and notes.',
                    highlighted: true,
                    onTap: () => _openMember(context),
                  ),
                  const SizedBox(height: 16),
                  _PortalCard(
                    tag: 'Teachers & subscribers',
                    title: 'Admin',
                    subtitle: 'Staff workspace',
                    description: 'Run your groups, share your class code, and manage fees.',
                    highlighted: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminEntry()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PortalCard(
                    tag: 'Platform',
                    title: 'Super admin',
                    subtitle: 'Plans and subscribers',
                    description:
                        'Manage plans, subscribers, and this public site.',
                    highlighted: false,
                    onTap: () => _notAvailable(context, 'Super admin'),
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

class _PortalCard extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final String description;
  final bool highlighted;
  final VoidCallback onTap;

  const _PortalCard({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navy = Theme.of(context).colorScheme.onSurface;
    const teal = Color(0xFF1B9A85);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: highlighted ? teal.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: highlighted
                    ? teal.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tr(tag),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: highlighted ? teal : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(title),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: navy,
              ),
            ),
            Text(
              tr(subtitle),
              style: const TextStyle(color: teal, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(tr(description), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: highlighted
                  ? FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(tr('Sign in')),
                    )
                  : OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(tr('Sign in')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}










