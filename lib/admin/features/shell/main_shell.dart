import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/admin_exit.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final session = ref.watch(sessionProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.school, color: AppColors.accent, size: 28),
        ),
        actions: [
          if (AdminExit.maybeOf(context) != null)
            IconButton(
              tooltip: isTamil ? 'Portal-க்குத் திரும்பு' : 'Back to Portal',
              icon: const Icon(Icons.home_outlined, size: 22),
              onPressed: AdminExit.maybeOf(context),
            ),
          // Language Quick Switch
          IconButton(
            tooltip: isTamil ? 'Switch to English' : 'தமிழுக்கு மாறவும்',
            icon: const Icon(
              Icons.translate,
              size: 20,
              color: AppColors.accent,
            ),
            onPressed: () =>
                ref.read(languageProvider.notifier).toggleLanguage(),
          ),
          // AI Teacher shortcut button
          IconButton(
            tooltip: 'AI Teacher',
            icon: const Icon(
              Icons.auto_awesome,
              color: AppColors.brandGreen,
              size: 22,
            ),
            onPressed: () => context.push('/app/ai-teacher'),
          ),
          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 4),
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
              leading: const Icon(
                Icons.dashboard_outlined,
                color: AppColors.accent,
              ),
              title: Text(isTamil ? 'முகப்பு பலகை' : 'Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/app');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.groups_outlined,
                color: AppColors.brandBlue,
              ),
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
                Icons.auto_awesome,
                color: AppColors.brandGreen,
              ),
              title: Text(isTamil ? 'AI ஆசிரியர்' : 'AI Teacher Assistant'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              trailing: const Icon(Icons.swap_horiz),
              onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
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
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: isTamil ? 'முகப்பு' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_outlined),
            activeIcon: const Icon(Icons.groups),
            label: isTamil ? 'குழுக்கள்' : 'Groups',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: isTamil ? 'அரட்டை' : 'Chat',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.video_call_outlined),
            activeIcon: const Icon(Icons.video_call),
            label: isTamil ? 'கூட்டம்' : 'Meetings',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: isTamil ? 'நூலகம்' : 'Library',
          ),
        ],
      ),
    );
  }
}
