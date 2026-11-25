import 'package:material_ui/material_ui.dart';

import 'admin/admin_entry.dart';
import 'admin/features/ai_teacher/screens/ai_teacher_entry.dart';
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

  void _openAiAssistant(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiTeacherEntry(onExit: () => Navigator.pop(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    const outer = Colors.white;
    const ink = Color(0xFF1F2937);
    const muted = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: outer,
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Center(
              child: Text(
                '© ${DateTime.now().year} Airo Techhub',
                key: const ValueKey('portal-footer'),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelHeight = constraints.maxHeight > 120
                ? constraints.maxHeight - 56
                : constraints.maxHeight;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 40, 14, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    minHeight: panelHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 194,
                                  height: 42,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _openAdmin(context),
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 19,
                              ),
                              label: Text(AppSettings.instance.tr('Admin')),
                              style: FilledButton.styleFrom(
                                backgroundColor: teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          AppSettings.instance.tr('Welcome back'),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 28,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppSettings.instance.tr(
                            'Sign in to continue to your portal',
                          ),
                          style: TextStyle(
                            color: muted,
                            fontSize: 17,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _MemberPortalCard(
                          title: AppSettings.instance.tr('Student or member'),
                          subtitle: AppSettings.instance.tr(
                            'Class, chat, meetings, and notes',
                          ),
                          buttonLabel: AppSettings.instance.tr(
                            'Sign in with phone',
                          ),
                          onTap: () => _openMember(context),
                        ),
                        const SizedBox(height: 18),
                        _AiAssistantCard(
                          title: AppSettings.instance.tr('AI assistant'),
                          subtitle: AppSettings.instance.tr(
                            'Ask questions, get quick help',
                          ),
                          onTap: () => _openAiAssistant(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MemberPortalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _MemberPortalCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    const ink = Color(0xFF1F2937);
    const muted = Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF4EE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF087C68),
                  size: 32,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 62,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.phone_outlined, size: 20),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AiAssistantCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1F2937);
    const muted = Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF64748B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF64748B),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
