import 'package:material_ui/material_ui.dart';

import 'app_settings.dart';
import 'home_shell.dart';
import 'mock_data.dart';
import 'phone_sign_in_screen.dart';
import 'portal_screen.dart';

class ApplicationScreen extends StatefulWidget {
  final Member member;

  const ApplicationScreen({super.key, required this.member});

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  Group? _selected;

  void _goToSite() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PortalScreen(memberPage: const PhoneSignInScreen()),
      ),
      (route) => false,
    );
  }

  Widget _buildLanguageSelector() {
    const teal = Color(0xFF1B9A85);
    final settings = AppSettings.instance;
    const languages = [('English', 'EN'), ('Tamil', 'த'), ('Sinhala', 'සි')];

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (language, label) in languages)
            InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () => settings.setLanguage(language),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: settings.language == language
                      ? teal
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: settings.language == language
                        ? Colors.white
                        : const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    final groups = MockDb.groupsForMember(widget.member);

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _goToSite,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                              child: Text(AppSettings.instance.tr('Home')),
                            ),
                            _buildLanguageSelector(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 140,
                                      height: 68,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Choose an application',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  for (final group in groups)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 7),
                                      child: _ApplicationCard(
                                        group: group,
                                        selected: _selected?.id == group.id,
                                        onTap: () =>
                                            setState(() => _selected = group),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 44,
                                    child: FilledButton(
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
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'CONTINUE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: _goToSite,
                                    style: TextButton.styleFrom(
                                      foregroundColor: teal,
                                    ),
                                    child: Text(
                                      AppSettings.instance.tr(
                                        'Back to the site',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 12),
                        child: Center(
                          child: Text(
                            '© ${DateTime.now().year} Airo Techhub',
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

class _ApplicationCard extends StatelessWidget {
  final Group group;
  final bool selected;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);

    return Material(
      color: selected ? const Color(0xFFDCEFED) : Colors.white,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? teal : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 38,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.school_outlined, color: teal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (group.teacher.isNotEmpty)
                      Text(
                        group.teacher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
