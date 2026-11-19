import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin/admin_entry.dart';
import 'app_settings.dart';

class PortalScreen extends StatelessWidget {
  final Widget memberPage;

  const PortalScreen({super.key, required this.memberPage});

  void _openMember(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => memberPage));
  }

  void _openAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEntry()),
    );
  }

  Future<void> _openWebsite(BuildContext context) async {
    final uri = Uri.parse('https://app.airotechhub.lk');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open website.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final navy = Theme.of(context).colorScheme.onSurface;
    const teal = Color(0xFF1B9A85);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top logo and Admin button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 48,
                        fit: BoxFit.contain,
                      ),

                      FilledButton.icon(
                        onPressed: () => _openAdmin(context),
                        icon: const Icon(Icons.admin_panel_settings, size: 18),
                        label: const Text('Admin Sign in'),
                        style: FilledButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Portal heading
                  Text(
                    tr('SIGN IN TO A PORTAL'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: teal,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    tr('Choose your portal'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Member card
                  _PortalCard(
                    tag: 'Students & members',
                    title: 'Member',
                    subtitle: 'Phone sign in',
                    description: 'Join your teacher\'s class, chat, meetings, and notes.',
                    highlighted: true,
                    onTap: () => _openMember(context),
                  ),

                  const SizedBox(height: 10),

                  // Website link
                  Center(
                    child: InkWell(
                      onTap: () => _openWebsite(context),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Text(
                          'App.airotechhub.lk',
                          style: TextStyle(
                            color: teal,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: teal,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // AI Teacher information card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF202D59),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'AI Teacher',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Ask a question, set an exam, or write notes. '
                          'It works in English and Tamil, and the result '
                          'can be saved in the library.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
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
                color: teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tr(tag),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: teal,
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

            const Text(
              'Phone sign in',
              style: TextStyle(color: teal, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Text(
              tr(description),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
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
