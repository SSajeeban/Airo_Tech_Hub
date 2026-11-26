import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/providers/app_providers.dart';

String _adminText(
  String language,
  String english,
  String tamil,
  String sinhala,
) {
  switch (language) {
    case 'ta':
      return tamil;
    case 'si':
      return sinhala;
    default:
      return english;
  }
}

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  static const _taShortMonths = [
    'ஜன',
    'பிப்',
    'மார்',
    'ஏப்',
    'மே',
    'ஜூன்',
    'ஜூலை',
    'ஆக',
    'செப்',
    'அக்',
    'நவ',
    'டிச',
  ];
  static const _siShortMonths = [
    'ජන',
    'පෙබ',
    'මාර්',
    'අප්‍රේ',
    'මැයි',
    'ජූනි',
    'ජූලි',
    'අගෝ',
    'සැප්',
    'ඔක්',
    'නොවැ',
    'දෙසැ',
  ];

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/app/groups')) return 1;
    if (location.startsWith('/app/chat')) return 2;
    if (location.startsWith('/app/meetings')) return 3;
    if (location.startsWith('/app/library')) return 4;
    return 0; // Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/app');
        break;
      case 1:
        context.go('/app/groups');
        break;
      case 2:
        context.go('/app/chat');
        break;
      case 3:
        context.go('/app/meetings');
        break;
      case 4:
        context.go('/app/library');
        break;
    }
  }

  Widget _navIcon(IconData icon, int index, int selectedIndex) {
    return AnimatedScale(
      scale: selectedIndex == index ? 1.12 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final session = ref.watch(sessionProvider);
    final currentLang = ref.watch(languageProvider);
    final isTamil = currentLang == 'ta';
    final isSinhala = currentLang == 'si';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notices = ref.watch(noticesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showDateTime = screenWidth >= 760;
    final showProfileName = screenWidth >= 600;
    final displayName = session?.user.displayName.trim().isNotEmpty == true
        ? session!.user.displayName.trim()
        : 'Educator';
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: screenWidth >= 1000 ? 72 : null,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: _adminText(
              currentLang,
              'Open navigation menu',
              'வழிசெலுத்தல் மெனு',
              'සංචාලන මෙනුව විවෘත කරන්න',
            ),
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: screenWidth < 380 ? 4 : 16,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.transparent : Colors.white,
          ),
          child: Image.asset(
            isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.school_outlined,
              color: AppColors.accent,
              size: 28,
            ),
          ),
        ),
        actions: [
          if (showDateTime) ...[
            Center(
              child: Text(
                isTamil
                    ? '${_now.day.toString().padLeft(2, '0')} ${_taShortMonths[_now.month - 1]} ${_now.year}  |  ${DateFormat('HH:mm:ss').format(_now)}'
                    : isSinhala
                    ? '${_now.day.toString().padLeft(2, '0')} ${_siShortMonths[_now.month - 1]} ${_now.year}  |  ${DateFormat('HH:mm:ss').format(_now)}'
                    : DateFormat('dd MMM yyyy  |  HH:mm:ss').format(_now),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: _adminText(
              currentLang,
              'Notifications',
              'அறிவிப்புகள்',
              'දැනුම්දීම්',
            ),
            icon: Badge.count(
              count: notices.length,
              child: const Icon(AppIcons.notification),
            ),
            onPressed: () => context.push('/app/notices'),
          ),
          if (screenWidth < 380)
            _buildCompactSettingsMenu(currentLang, isDark)
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: _languageSwitch(
                  currentLanguage: currentLang,
                  onEnglish: () =>
                      ref.read(languageProvider.notifier).setLanguage('en'),
                  onTamil: () =>
                      ref.read(languageProvider.notifier).setLanguage('ta'),
                  onSinhala: () =>
                      ref.read(languageProvider.notifier).setLanguage('si'),
                ),
              ),
            ),
            IconButton(
              tooltip: isDark
                  ? _adminText(
                      currentLang,
                      'Light theme',
                      'ஒளி பயன்முறை',
                      'ආලෝක මාදිලිය',
                    )
                  : _adminText(
                      currentLang,
                      'Dark theme',
                      'இருள் பயன்முறை',
                      'අඳුරු මාදිලිය',
                    ),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: VerticalDivider(width: 1),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => context.go('/app/profile'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showProfileName) ...[
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isDark
                            ? AppColors.headingDark
                            : AppColors.headingLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      initials.isEmpty ? 'A' : initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.headingLight, AppColors.accentHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  session?.user.displayName.isNotEmpty == true
                      ? session!.user.displayName[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
              accountName: Text(
                session?.user.displayName ?? 'Educator / Subscriber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                session?.user.email ?? 'educator@airotechhub.lk',
              ),
            ),

            ListTile(
              leading: const Icon(AppIcons.home, color: AppColors.accent),
              title: Text(
                _adminText(
                  currentLang,
                  'Dashboard',
                  'முகப்பு பலகை',
                  'මුල් පිටුව',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/app');
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.groups, color: AppColors.brandBlue),
              title: Text(
                _adminText(
                  currentLang,
                  'Groups & Classes',
                  'குழுக்கள் & வகுப்புகள்',
                  'කණ්ඩායම් සහ පන්ති',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/app/groups');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.people_outline,
                color: AppColors.brandGreen,
              ),
              title: Text(
                _adminText(
                  currentLang,
                  'Members Directory',
                  'உறுப்பினர்கள் & மாணவர்கள்',
                  'සාමාජික ලැයිස්තුව',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/app/members');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.campaign_outlined,
                color: AppColors.warning,
              ),
              title: Text(
                _adminText(
                  currentLang,
                  'Notices & Bulletins',
                  'அறிவிப்புகள்',
                  'දැනුම්දීම් සහ නිවේදන',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/app/notices');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.payment_outlined,
                color: AppColors.brandBlue,
              ),
              title: Text(
                _adminText(
                  currentLang,
                  'Payments & Tuition',
                  'கட்டணங்கள் & விலை',
                  'ගෙවීම් සහ ගාස්තු',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/app/payments');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.fiber_manual_record_outlined,
                color: AppColors.danger,
              ),
              title: Text(
                _adminText(
                  currentLang,
                  'Recording',
                  'பதிவுகள்',
                  'පටිගත කිරීම්',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/app/recording');
              },
            ),
            if (selectedIndex == 0)
              ListTile(
                leading: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.brandGreen,
                ),
                title: Text(
                  _adminText(
                    currentLang,
                    'AI Teacher Assistant',
                    'AI ஆசிரியர்',
                    'AI ගුරු සහායක',
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/app/ai-teacher');
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.business_outlined,
                color: AppColors.mutedLight,
              ),
              title: Text(
                _adminText(
                  currentLang,
                  'Profile & Custom Branding',
                  'சுயவிவரம் & லோகோ',
                  'පැතිකඩ සහ සන්නාම සැකසුම්',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/app/profile');
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(
                _adminText(
                  currentLang,
                  'Language: English',
                  'மொழி: தமிழ்',
                  'භාෂාව: සිංහල',
                ),
              ),
              trailing: const Icon(Icons.swap_horiz_rounded),
              onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
            ),

            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
              ),
              title: Text(
                _adminText(currentLang, 'Log Out', 'வெளியேறு', 'ඉවත් වන්න'),
                style: const TextStyle(color: AppColors.danger),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(sessionProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ],
        ),
      ),
      body: screenWidth >= 1000
          ? Row(
              children: [
                _buildDesktopSidebar(
                  context,
                  isTamil: isTamil,
                  isSinhala: isSinhala,
                  selectedIndex: selectedIndex,
                ),
                Expanded(child: widget.child),
              ],
            )
          : widget.child,
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              heroTag: 'ai-teacher-fab',
              tooltip: _adminText(
                currentLang,
                'AI Teacher',
                'AI ஆசிரியர்',
                'AI ගුරුවරයා',
              ),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              onPressed: () => context.push('/app/ai-teacher'),
              child: const Icon(Icons.auto_awesome_outlined, size: 24),
            )
          : null,
      bottomNavigationBar: screenWidth < 1000
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              showSelectedLabels: screenWidth >= 380,
              showUnselectedLabels: screenWidth >= 380,
              onTap: (index) => _onItemTapped(index, context),
              items: [
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.home, 0, selectedIndex),
                  activeIcon: _navIcon(AppIcons.homeActive, 0, selectedIndex),
                  label: _adminText(
                    currentLang,
                    'Home',
                    'முகப்பு',
                    'මුල් පිටුව',
                  ),
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.groups, 1, selectedIndex),
                  activeIcon: _navIcon(AppIcons.groupsActive, 1, selectedIndex),
                  label: _adminText(
                    currentLang,
                    'Groups',
                    'குழுக்கள்',
                    'කණ්ඩායම්',
                  ),
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.chat, 2, selectedIndex),
                  activeIcon: _navIcon(AppIcons.chatActive, 2, selectedIndex),
                  label: _adminText(currentLang, 'Chat', 'அரட்டை', 'කතාබස්'),
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.meetings, 3, selectedIndex),
                  activeIcon: _navIcon(
                    AppIcons.meetingsActive,
                    3,
                    selectedIndex,
                  ),
                  label: _adminText(
                    currentLang,
                    'Meetings',
                    'கூட்டம்',
                    'රැස්වීම්',
                  ),
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.library, 4, selectedIndex),
                  activeIcon: _navIcon(
                    AppIcons.libraryActive,
                    4,
                    selectedIndex,
                  ),
                  label: _adminText(
                    currentLang,
                    'Library',
                    'நூலகம்',
                    'පුස්තකාලය',
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context, {
    required bool isTamil,
    required bool isSinhala,
    required int selectedIndex,
  }) {
    final language = isSinhala
        ? 'si'
        : isTamil
        ? 'ta'
        : 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.lineDark : AppColors.lineLight;
    return Container(
      width: 343,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: dividerColor)),
      ),
      child: Material(
        color: isDark ? AppColors.cardDark : const Color(0xFFF8F9FB),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            _desktopSectionLabel(
              _adminText(language, 'PEOPLE', 'மக்கள்', 'පුද්ගලයින්'),
            ),
            _desktopNavItem(
              context,
              AppIcons.groups,
              _adminText(language, 'Groups', 'குழுக்கள்', 'කණ්ඩායම්'),
              selectedIndex == 1,
              () => context.go('/app/groups'),
            ),
            _desktopNavItem(
              context,
              Icons.person_outline_rounded,
              _adminText(language, 'Members', 'உறுப்பினர்கள்', 'සාමාජිකයින්'),
              false,
              () => context.go('/app/members'),
            ),
            _desktopSectionLabel(
              _adminText(language, 'MESSAGES', 'செய்திகள்', 'පණිවිඩ'),
            ),
            _desktopNavItem(
              context,
              AppIcons.chat,
              _adminText(language, 'Chat', 'அரட்டை', 'කතාබස්'),
              selectedIndex == 2,
              () => context.go('/app/chat'),
            ),
            _desktopNavItem(
              context,
              Icons.article_outlined,
              _adminText(language, 'Notices', 'அறிவிப்புகள்', 'දැනුම්දීම්'),
              false,
              () => context.go('/app/notices'),
            ),
            _desktopNavItem(
              context,
              Icons.credit_card_outlined,
              _adminText(language, 'Payments', 'கட்டணங்கள்', 'ගෙවීම්'),
              false,
              () => context.go('/app/payments'),
            ),
            _desktopSectionLabel(
              _adminText(language, 'LEARN', 'கற்றல்', 'ඉගෙනීම'),
            ),
            _desktopNavItem(
              context,
              AppIcons.meetings,
              _adminText(language, 'Meetings', 'கூட்டங்கள்', 'රැස්වීම්'),
              selectedIndex == 3,
              () => context.go('/app/meetings'),
            ),
            _desktopNavItem(
              context,
              Icons.radio_button_checked_outlined,
              _adminText(language, 'Recording', 'பதிவுகள்', 'පටිගත කිරීම්'),
              false,
              () => context.go('/app/recording'),
            ),
            _desktopNavItem(
              context,
              AppIcons.library,
              _adminText(language, 'Library', 'நூலகம்', 'පුස්තකාලය'),
              selectedIndex == 4,
              () => context.go('/app/library'),
            ),
            _desktopNavItem(
              context,
              Icons.auto_awesome_outlined,
              _adminText(language, 'AI Teacher', 'AI ஆசிரியர்', 'AI ගුරුවරයා'),
              false,
              () => context.go('/app/ai-teacher'),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
              child: Text(
                '© 2026 Airo Techhub',
                style: TextStyle(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageSwitch({
    required String currentLanguage,
    required VoidCallback onEnglish,
    required VoidCallback onTamil,
    required VoidCallback onSinhala,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _languageSegment(
            label: 'EN',
            selected: currentLanguage == 'en',
            onTap: onEnglish,
          ),
          const SizedBox(width: 2),
          _languageSegment(
            label: 'த',
            selected: currentLanguage == 'ta',
            onTap: onTamil,
          ),
          const SizedBox(width: 2),
          _languageSegment(
            label: 'සි',
            selected: currentLanguage == 'si',
            onTap: onSinhala,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSettingsMenu(String language, bool isDark) {
    return PopupMenuButton<String>(
      key: const ValueKey('admin-compact-settings'),
      tooltip: _adminText(language, 'Settings', 'அமைப்புகள்', 'සැකසීම්'),
      onSelected: (value) {
        if (value == 'theme') {
          ref.read(themeModeProvider.notifier).toggleTheme();
        } else {
          ref.read(languageProvider.notifier).setLanguage(value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              const SizedBox(width: 12),
              Text(
                isDark
                    ? _adminText(
                        language,
                        'Light theme',
                        'ஒளி பயன்முறை',
                        'ආලෝක මාදිලිය',
                      )
                    : _adminText(
                        language,
                        'Dark theme',
                        'இருள் பயன்முறை',
                        'අඳුරු මාදිලිය',
                      ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final (code, label) in [
          ('en', 'English'),
          ('ta', 'தமிழ்'),
          ('si', 'සිංහල'),
        ])
          PopupMenuItem(
            value: code,
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (language == code)
                  const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
    );
  }

  Widget _languageSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 28,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _desktopSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 16, 10, 7),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.mutedLight,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _desktopNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        minTileHeight: 50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: selected ? AppColors.accent : null,
        leading: Icon(
          icon,
          size: 24,
          color: selected
              ? Colors.white
              : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? AppColors.inkDark : AppColors.mutedLight),
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
