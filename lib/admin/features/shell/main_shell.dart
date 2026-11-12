import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/providers/app_providers.dart';

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
    final isTamil = ref.watch(languageProvider) == 'ta';
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
            tooltip: isTamil ? 'வழிசெலுத்தல் மெனு' : 'Open navigation menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.school_outlined,
            color: AppColors.accent,
            size: 28,
          ),
        ),
        actions: [
          if (showDateTime) ...[
            Center(
              child: Text(
                DateFormat('dd MMM yyyy  |  HH:mm:ss').format(_now),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: isTamil ? 'அறிவிப்புகள்' : 'Notifications',
            icon: Badge.count(
              count: notices.length,
              child: const Icon(AppIcons.notification),
            ),
            onPressed: () => context.push('/app/notices'),
          ),
          IconButton(
            tooltip: isTamil ? 'Switch to English' : 'தமிழுக்கு மாறவும்',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 19, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  isTamil ? 'த' : 'EN',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            onPressed: () =>
                ref.read(languageProvider.notifier).toggleLanguage(),
          ),
          IconButton(
            tooltip: isDark ? 'Light theme' : 'Dark theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: VerticalDivider(width: 1),
          ),
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
              title: Text(isTamil ? 'முகப்பு பலகை' : 'Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/app');
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.groups, color: AppColors.brandBlue),
              title: Text(
                isTamil ? 'குழுக்கள் & வகுப்புகள்' : 'Groups & Classes',
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
                isTamil ? 'உறுப்பினர்கள் & மாணவர்கள்' : 'Members Directory',
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
              title: Text(isTamil ? 'அறிவிப்புகள்' : 'Notices & Bulletins'),
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
              title: Text(isTamil ? 'கட்டணங்கள் & விலை' : 'Payments & Tuition'),
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
              title: Text(isTamil ? 'பதிவுகள்' : 'Recording'),
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
                title: Text(isTamil ? 'AI ஆசிரியர்' : 'AI Teacher Assistant'),
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
                isTamil ? 'சுயவிவரம் & லோகோ' : 'Profile & Custom Branding',
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/app/profile');
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(isTamil ? 'மொழி: தமிழ்' : 'Language: English'),
              trailing: const Icon(Icons.swap_horiz_rounded),
              onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
            ),

            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
              ),
              title: Text(
                isTamil ? 'வெளியேறு' : 'Log Out',
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
                  selectedIndex: selectedIndex,
                ),
                Expanded(child: widget.child),
              ],
            )
          : widget.child,
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              heroTag: 'ai-teacher-fab',
              tooltip: isTamil ? 'AI ஆசிரியர்' : 'AI Teacher',
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
              onTap: (index) => _onItemTapped(index, context),
              items: [
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.home, 0, selectedIndex),
                  activeIcon: _navIcon(AppIcons.homeActive, 0, selectedIndex),
                  label: isTamil ? 'முகப்பு' : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.groups, 1, selectedIndex),
                  activeIcon: _navIcon(AppIcons.groupsActive, 1, selectedIndex),
                  label: isTamil ? 'குழுக்கள்' : 'Groups',
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.chat, 2, selectedIndex),
                  activeIcon: _navIcon(AppIcons.chatActive, 2, selectedIndex),
                  label: isTamil ? 'அரட்டை' : 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.meetings, 3, selectedIndex),
                  activeIcon: _navIcon(
                    AppIcons.meetingsActive,
                    3,
                    selectedIndex,
                  ),
                  label: isTamil ? 'கூட்டம்' : 'Meetings',
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(AppIcons.library, 4, selectedIndex),
                  activeIcon: _navIcon(
                    AppIcons.libraryActive,
                    4,
                    selectedIndex,
                  ),
                  label: isTamil ? 'நூலகம்' : 'Library',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context, {
    required bool isTamil,
    required int selectedIndex,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.lineDark : AppColors.lineLight;
    return Container(
      width: 343,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF8F9FB),
        border: Border(right: BorderSide(color: dividerColor)),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _desktopSectionLabel(isTamil ? 'மக்கள்' : 'PEOPLE'),
          _desktopNavItem(
            context,
            AppIcons.groups,
            isTamil ? 'குழுக்கள்' : 'Groups',
            selectedIndex == 1,
            () => context.go('/app/groups'),
          ),
          _desktopNavItem(
            context,
            Icons.person_outline_rounded,
            isTamil ? 'உறுப்பினர்கள்' : 'Members',
            false,
            () => context.go('/app/members'),
          ),
          _desktopSectionLabel(isTamil ? 'செய்திகள்' : 'MESSAGES'),
          _desktopNavItem(
            context,
            AppIcons.chat,
            isTamil ? 'அரட்டை' : 'Chat',
            selectedIndex == 2,
            () => context.go('/app/chat'),
          ),
          _desktopNavItem(
            context,
            Icons.article_outlined,
            isTamil ? 'அறிவிப்புகள்' : 'Notices',
            false,
            () => context.go('/app/notices'),
          ),
          _desktopNavItem(
            context,
            Icons.credit_card_outlined,
            isTamil ? 'கட்டணங்கள்' : 'Payments',
            false,
            () => context.go('/app/payments'),
          ),
          _desktopSectionLabel(isTamil ? 'கற்றல்' : 'LEARN'),
          _desktopNavItem(
            context,
            AppIcons.meetings,
            isTamil ? 'கூட்டங்கள்' : 'Meetings',
            selectedIndex == 3,
            () => context.go('/app/meetings'),
          ),
          _desktopNavItem(
            context,
            Icons.radio_button_checked_outlined,
            isTamil ? 'பதிவுகள்' : 'Recording',
            false,
            () => context.go('/app/recording'),
          ),
          _desktopNavItem(
            context,
            AppIcons.library,
            isTamil ? 'நூலகம்' : 'Library',
            selectedIndex == 4,
            () => context.go('/app/library'),
          ),
          _desktopNavItem(
            context,
            Icons.auto_awesome_outlined,
            isTamil ? 'AI ஆசிரியர்' : 'AI Teacher',
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
    return ListTile(
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
    );
  }
}
