import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/core/providers/app_providers.dart';
import 'admin/core/services/storage_service.dart';
import 'admin/features/ai_teacher/screens/ai_teacher_screen.dart';
import 'chat_tab.dart';
import 'meetings_tab.dart';
import 'notices_tab.dart';
import 'mock_data.dart';
import 'library_tab.dart';
import 'timetable_board.dart';
import 'app_settings.dart';

class HomeShell extends StatefulWidget {
  final Member member;
  final Group group;

  const HomeShell({super.key, required this.member, required this.group});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String _tr(String value) => AppSettings.instance.tr(value);
  int _index = 0;
  bool _sidebarExpanded = true;
  String get _language => AppSettings.instance.language;
  bool get _isTamil => AppSettings.instance.isTamil;

  bool _isDarkMode = false;
  late String _memberName;
  late String _memberPhone;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  Timer? _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _memberName = widget.member.name;
    _memberPhone = widget.member.phone;
    _nameController = TextEditingController(text: _memberName);
    _phoneController = TextEditingController(text: _memberPhone);
    unawaited(_loadSavedProfile());
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    if (mounted) {
      setState(() {
        _currentTime = AppDateHelper.formatClock(DateTime.now());
      });
    }
  }

  String get _profileNameKey => 'member_${widget.member.id}_name';
  String get _profilePhoneKey => 'member_${widget.member.id}_phone';

  Future<void> _loadSavedProfile() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final name = preferences.getString(_profileNameKey);
      final phone = preferences.getString(_profilePhoneKey);
      if (!mounted || (name == null && phone == null)) return;

      setState(() {
        _memberName = name ?? _memberName;
        _memberPhone = phone ?? _memberPhone;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load saved profile: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);
    final isWide = MediaQuery.of(context).size.width >= 800;
    final notices = MockDb.notices
        .where((notice) => notice.groupId == widget.group.id)
        .toList();
    final isDark = _isDarkMode;
    final theme = ThemeData(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: teal,
            brightness: isDark ? Brightness.dark : Brightness.light,
          ).copyWith(
            surface: isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF),
            surfaceContainerHighest: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF1F5F9),
            outline: isDark ? const Color(0xFF4B5563) : const Color(0xFFE2E8F0),
          ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF8FAFB),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      useMaterial3: true,
    );

    final pages = <Widget>[
      _HomeTab(member: _currentMember, group: widget.group, isTamil: _isTamil),
      ChatTab(memberName: _memberName),
      NoticesTab(
        notices: MockDb.notices
            .where((n) => n.groupId == widget.group.id)
            .toList(),
        group: widget.group,
        member: _currentMember,
      ),
      MeetingsTab(
        memberName: _memberName,
        groupName: widget.group.name,
        isTamil: _isTamil,
      ),
      const LibraryTab(),
    ];

    if (isWide) {
      return Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: _isDarkMode
              ? const Color(0xFF111827)
              : const Color(0xFFF8FAFC),
          body: Column(
            children: [
              _buildTopAppBar(teal, notices),
              Divider(
                height: 1,
                thickness: 1,
                color: _isDarkMode
                    ? const Color(0xFF374151)
                    : const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: Row(
                  children: [
                    if (_sidebarExpanded) _buildSidebar(navy, teal),
                    Expanded(
                      child: Container(
                        color: _isDarkMode
                            ? const Color(0xFF111827)
                            : const Color(0xFFF8FAFB),
                        child: pages[_index],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _index == 1
              ? null
              : _buildAiTeacherButton(teal),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      );
    }

    // Mobile / Narrow screen layout
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _isDarkMode
            ? const Color(0xFF111827)
            : const Color(0xFFF8FAFB),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 48,
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: _tr('Menu'),
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: MediaQuery.sizeOf(context).width >= 420
              ? Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  errorBuilder: (_, __, ___) => Text(widget.group.name),
                )
              : null,
          actions: [
            _buildCompactClock(),
            _buildNotificationButton(notices),
            _buildThemeButton(),
            _buildLanguageToggle(teal),
            const SizedBox(width: 4),
            _buildProfileAvatar(teal),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: navy),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      backgroundColor: teal,
                      child: Text(
                        _memberName.isNotEmpty
                            ? _memberName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _memberName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(Icons.home_outlined, _tr('Home'), 0),
              _buildDrawerItem(Icons.chat_bubble_outline, _tr('Chat'), 1),
              _buildDrawerItem(Icons.description_outlined, _tr('Notices'), 2),
              _buildDrawerItem(Icons.videocam_outlined, _tr('Meetings'), 3),
              _buildDrawerItem(Icons.menu_book_outlined, _tr('Library'), 4),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(_tr('Payments')),
                subtitle: Text(_tr('Monthly fee due: Date not set')),
                onTap: _openPaymentReminder,
              ),
            ],
          ),
        ),
        body: pages[_index],
        floatingActionButton: _index == 1 ? null : _buildAiTeacherButton(teal),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: _tr('Home'),
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: _tr('Chat'),
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              label: _tr('Notices'),
            ),
            NavigationDestination(
              icon: Icon(Icons.videocam_outlined),
              label: _tr('Meetings'),
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: _tr('Library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(Color teal, List<Notice> notices) {
    final foreground = _isDarkMode ? Colors.white : Colors.black87;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      child: Row(
        children: [
          // Sidebar Toggle Button
          IconButton(
            icon: Icon(Icons.menu, color: foreground),
            onPressed: () =>
                setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          const SizedBox(width: 8),

          // Logo
          Image.asset(
            'assets/images/logo.png',
            height: 32,
            errorBuilder: (_, __, ___) => const Text(
              'AIRO TECHHUB',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B9A85),
                letterSpacing: 1.2,
              ),
            ),
          ),

          const Spacer(),

          // Live Clock (e.g. "10 Nov 2026 | 15:25:35")
          Text(
            _currentTime,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 16),

          // Notification Bell
          _buildNotificationButton(notices, foreground: foreground),
          const SizedBox(width: 10),

          // Language Selector [ EN | த | සි ]
          _buildLanguageToggle(teal),
          const SizedBox(width: 10),

          // Dark Mode Toggle Icon
          _buildThemeButton(foreground: foreground),
          const SizedBox(width: 14),

          // User Profile: Name and Avatar
          Text(
            _memberName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2A5A),
            ),
          ),
          const SizedBox(width: 8),
          _buildProfileAvatar(teal),
        ],
      ),
    );
  }

  Widget _buildCompactClock() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final date = '${now.day} ${AppDateHelper.months[now.month - 1]}';
    final time =
        '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(date, style: const TextStyle(fontSize: 10, height: 1.2)),
          Text(time, style: const TextStyle(fontSize: 10, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(List<Notice> notices, {Color? foreground}) {
    final dark = _isDarkMode;
    final iconColor = foreground ?? (dark ? Colors.white : Colors.black87);
    return IconButton(
      tooltip: _tr('Notifications'),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(7),
      onPressed: () => _showNotifications(notices),
      icon: Badge(
        isLabelVisible: notices.isNotEmpty,
        label: Text('${notices.length}'),
        child: Icon(
          Icons.notifications_none_outlined,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildThemeButton({Color? foreground}) {
    final dark = _isDarkMode;
    final iconColor = foreground ?? (dark ? Colors.white : Colors.black87);
    return IconButton(
      tooltip: dark
          ? (_tr('Switch to light mode'))
          : (_tr('Switch to dark mode')),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(7),
      icon: Icon(
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 18,
        color: iconColor,
      ),
      onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
    );
  }

  void _showNotifications(List<Notice> notices) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_none_outlined),
            const SizedBox(width: 8),
            Text(_tr('Notifications')),
          ],
        ),
        content: notices.isEmpty
            ? Text(
                _tr('You are all caught up. There are no notifications yet.'),
              )
            : SizedBox(
                width: 360,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final notice in notices)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.campaign_outlined),
                        title: Text(_tr(notice.title)),
                        subtitle: Text(_tr(notice.body)),
                      ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaymentReminder() async {
    Navigator.pop(context);
    await Future<void>.delayed(Duration.zero);
    if (mounted) {
      _showPaymentReminder();
    }
  }

  void _showPaymentReminder() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('Monthly fee reminder')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr('Monthly fee due: Date not set.')),
            const SizedBox(height: 8),
            Text(_tr('Ask your teacher for your due date and payment link.')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tr('Close')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _tr(
                      'Online payment is not set up yet. Please contact your teacher.',
                    ),
                  ),
                ),
              );
            },
            child: Text(_tr('Pay now')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(Color teal) {
    Widget languageOption(String value, String label) {
      final selected = _language == value;
      return InkWell(
        onTap: () {
          setState(() {
            AppSettings.instance.setLanguage(value);
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.grey.shade300 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          languageOption('English', 'EN'),
          languageOption('Tamil', 'த'),
          languageOption('Sinhala', 'සි'),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Color teal) {
    final initial = _memberName.isNotEmpty ? _memberName[0].toUpperCase() : 'A';
    return Tooltip(
      message: _tr('Profile'),
      child: Semantics(
        button: true,
        label: _tr('Profile'),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _showProfileDetails,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: teal,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Member get _currentMember => Member(
    id: widget.member.id,
    name: _memberName,
    phone: _memberPhone,
    groupId: widget.member.groupId,
  );

  Widget _buildAiTeacherButton(Color teal) {
    return FloatingActionButton(
      heroTag: 'member-ai-teacher',
      tooltip: _tr('AI Teacher'),
      backgroundColor: teal,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      onPressed: _openAiTeacher,
      child: const Icon(Icons.auto_awesome),
    );
  }

  Future<void> _openAiTeacher() async {
    try {
      final storage = await StorageService.init();
      await storage.setLanguage(
        _language == 'Tamil'
            ? 'ta'
            : _language == 'Sinhala'
            ? 'si'
            : 'en',
      );
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Theme(
            data: Theme.of(context),
            child: ProviderScope(
              overrides: [storageServiceProvider.overrideWithValue(storage)],
              child: const AiTeacherScreen(),
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open AI Teacher: $error')),
        );
      }
    }
  }

  Future<void> _showProfileDetails() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('Personal details')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileDetail(_tr('Name'), _memberName),
            const SizedBox(height: 12),
            _profileDetail(_tr('Phone'), _memberPhone),
            const SizedBox(height: 12),
            _profileDetail(_tr('Group'), widget.group.name),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tr('Close')),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _editProfile();
            },
            icon: const Icon(Icons.edit_outlined),
            label: Text(_tr('Edit profile')),
          ),
        ],
      ),
    );
  }

  Widget _profileDetail(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: colors.onSurface)),
      ],
    );
  }

  Future<void> _editProfile() async {
    _nameController.text = _memberName;
    _phoneController.text = _memberPhone;
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('Edit profile')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: _tr('Name')),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (_tr('Enter a name'))
                    : null,
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: _tr('Phone')),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (_tr('Enter a phone number'))
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(_tr('Save')),
          ),
        ],
      ),
    );

    if (updated == true && mounted) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      try {
        final preferences = await SharedPreferences.getInstance();
        final nameSaved = await preferences.setString(_profileNameKey, name);
        final phoneSaved = await preferences.setString(_profilePhoneKey, phone);
        if (!nameSaved || !phoneSaved) {
          throw StateError('The profile changes were not saved.');
        }

        if (mounted) {
          setState(() {
            _memberName = name;
            _memberPhone = phone;
          });
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save profile: $error')),
          );
        }
      }
    }
  }

  Widget _buildSidebar(Color navy, Color teal) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          right: BorderSide(
            color: _isDarkMode
                ? const Color(0xFF374151)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarNavItem(
            0,
            Icons.home_outlined,
            Icons.home,
            'Home',
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            1,
            Icons.chat_bubble_outline,
            Icons.chat_bubble,
            'Chat',
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            2,
            Icons.description_outlined,
            Icons.description,
            'Notices',
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            3,
            Icons.videocam_outlined,
            Icons.videocam,
            'Meetings',
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            4,
            Icons.menu_book_outlined,
            Icons.menu_book,
            'Library',
            teal,
          ),

          const Spacer(),
          // Footer from reference picture: "© 2026 Airo Techhub"
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              '© ${DateTime.now().year} Airo Techhub',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    Color teal,
  ) {
    final isSelected = _index == index;

    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? teal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? Colors.white
                  : (_isDarkMode ? Colors.white70 : Colors.black87),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (_isDarkMode ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _index == index,
      onTap: () {
        setState(() => _index = index);
        Navigator.pop(context);
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Member member;
  final Group group;
  final bool isTamil;

  const _HomeTab({
    required this.member,
    required this.group,
    required this.isTamil,
  });
  String _tr(String value) => AppSettings.instance.tr(value);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final notices = MockDb.notices.where((n) => n.groupId == group.id).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // Member Name Header
        Text(
          member.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ).copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: 12),

        // Notice board Title
        Text(
          _tr('Notice board'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ).copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: 4),

        // Notice Board Content
        if (notices.isEmpty)
          Text(
            _tr('No notices for you yet.'),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          )
        else
          Column(
            children: [
              for (final n in notices)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(top: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      _tr(n.title),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_tr(n.body)),
                  ),
                ),
            ],
          ),

        const SizedBox(height: 20),

        // TIMETABLE BOARD (WEEKLY / MONTHLY / YEARLY) & EVENT BOARD
        TimetableBoard(group: group, member: member),

        const SizedBox(height: 20),

        // Profile / Groups Usage Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${member.name} · Pro',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ).copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '${_tr('Your groups')}: ${group.name}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Groups usage rows
              _UsageRow(label: _tr('Groups'), used: 1, total: 20),
              _UsageRow(label: _tr('Members'), used: 22, total: 25),
              _UsageRow(
                label: _tr('Storage'),
                used: 0,
                total: 2,
                text: '0 B / 2.0 GB',
              ),
              _UsageRow(label: _tr('Meetings this month'), used: 0, total: 10),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final String? text;

  const _UsageRow({
    required this.label,
    required this.used,
    required this.total,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                text ?? '$used / $total',
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total == 0 ? 0 : used / total,
            color: teal,
            backgroundColor: colors.surfaceContainerHighest,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
