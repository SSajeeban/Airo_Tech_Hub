
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/core/constants/app_colors.dart';
import 'admin/core/constants/app_icons.dart';
import 'admin/core/providers/app_providers.dart';
import 'admin/core/services/storage_service.dart';
import 'admin/features/ai_teacher/screens/ai_teacher_screen.dart';
import 'chat_tab.dart';
import 'meetings_tab.dart';
import 'notices_tab.dart';
import 'mock_data.dart';
import 'library_tab.dart';
import 'mock_meeting_store.dart';
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
  String? _memberImage;
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
    MockMeetingStore.instance.addListener(_onMeetingsChanged);
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
  String get _profileImageKey => 'member_${widget.member.id}_image';

  Future<void> _loadSavedProfile() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final name = preferences.getString(_profileNameKey);
      final phone = preferences.getString(_profilePhoneKey);
      final image = preferences.getString(_profileImageKey);
      if (!mounted || (name == null && phone == null && image == null)) return;

      setState(() {
        _memberName = name ?? _memberName;
        _memberPhone = phone ?? _memberPhone;
        _memberImage = image ?? _memberImage;
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
    MockMeetingStore.instance.removeListener(_onMeetingsChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onMeetingsChanged() {
    if (mounted) setState(() {});
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
      brightness: isDark ? Brightness.dark : Brightness.light,
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
            outlineVariant: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFE2E8F0),
            onSurface: isDark ? Colors.white : const Color(0xFF1F2937),
            onSurfaceVariant: isDark
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
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
      _HomeTab(
        member: _currentMember,
        group: widget.group,
        isTamil: _isTamil,
        isDark: isDark,
      ),
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
        groupId: widget.group.id,
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
          floatingActionButton: _index == 0
              ? _buildAiTeacherButton(teal)
              : null,
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
                  errorBuilder: (_, _, _) => Text(widget.group.name),
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
          backgroundColor: theme.colorScheme.surface,
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
                  backgroundImage: _memberImage != null
                      ? MemoryImage(base64Decode(_memberImage!))
                      : null,
                  child: _memberImage == null
                      ? Text(
                          _memberName.isNotEmpty
                              ? _memberName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                accountName: Text(
                  _memberName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(widget.group.name),
              ),
              _buildDrawerItem(
                AppIcons.home,
                AppIcons.homeActive,
                _tr('Home'),
                0,
                AppColors.accent,
                teal,
              ),
              _buildDrawerItem(
                AppIcons.chat,
                AppIcons.chatActive,
                _tr('Chat'),
                1,
                AppColors.brandBlue,
                teal,
              ),
              _buildDrawerItem(
                Icons.campaign_outlined,
                Icons.campaign,
                _tr('Notices'),
                2,
                AppColors.warning,
                teal,
              ),
              _buildDrawerItem(
                AppIcons.meetings,
                AppIcons.meetingsActive,
                _tr('Meetings'),
                3,
                AppColors.brandBlue,
                teal,
              ),
              _buildDrawerItem(
                AppIcons.library,
                AppIcons.libraryActive,
                _tr('Library'),
                4,
                AppColors.brandGreen,
                teal,
              ),
              ListTile(
                leading: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.brandBlue,
                ),
                title: Text(
                  _tr('Payments'),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  _tr('Monthly fee due: Date not set'),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                onTap: _openPaymentReminder,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.switch_account_outlined,
                  color: Colors.redAccent,
                ),
                title: Text(
                  _isTamil
                      ? 'சுயவிவரம் மாற்று / வெளியேறு'
                      : 'Switch profile / Exit',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '© ${DateTime.now().year} Airo Techhub',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: pages[_index],
        floatingActionButton: _index == 0 ? _buildAiTeacherButton(teal) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: Icon(AppIcons.home),
              selectedIcon: Icon(AppIcons.homeActive),
              label: _tr('Home'),
            ),
            NavigationDestination(
              icon: Icon(AppIcons.chat),
              selectedIcon: Icon(AppIcons.chatActive),
              label: _tr('Chat'),
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: _tr('Notices'),
            ),
            NavigationDestination(
              icon: Icon(AppIcons.meetings),
              selectedIcon: Icon(AppIcons.meetingsActive),
              label: _tr('Meetings'),
            ),
            NavigationDestination(
              icon: Icon(AppIcons.library),
              selectedIcon: Icon(AppIcons.libraryActive),
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
          IconButton(
            icon: Icon(Icons.menu, color: foreground),
            onPressed: () =>
                setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/logo.png',
            height: 36,
            errorBuilder: (_, _, _) => const Text(
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
          _buildNotificationButton(notices, foreground: foreground),
          const SizedBox(width: 10),
          _buildLanguageToggle(teal),
          const SizedBox(width: 10),
          _buildThemeButton(foreground: foreground),
          const SizedBox(width: 14),
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
    final meetingNotifications = MockMeetingStore.instance
        .notificationsForMemberGroup(widget.group.id);
    final notificationCount = notices.length + meetingNotifications.length;
    return IconButton(
      tooltip: _tr('Notifications'),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(7),
      onPressed: () => _showNotifications(notices, meetingNotifications),
      icon: Badge(
        isLabelVisible: notificationCount > 0,
        label: Text('$notificationCount'),
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
      onPressed: () {
        setState(() => _isDarkMode = !_isDarkMode);
        AppSettings.instance.themeMode =
            _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      },
    );
  }

  void _showNotifications(
    List<Notice> notices,
    List<MockMeetingNotification> meetingNotifications,
  ) {
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
        content: notices.isEmpty && meetingNotifications.isEmpty
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
                    for (final notification in meetingNotifications)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.videocam_outlined),
                        title: Text(notification.meeting.title),
                        subtitle: Text(
                          '${notification.meeting.groupName} · '
                          '${DateFormat('dd MMM yyyy, h:mm a').format(notification.meeting.scheduledTime)}\n'
                          '${notification.meeting.meetingUrl}',
                        ),
                        isThreeLine: true,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? teal : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : (_isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF475569)),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF374151) : Colors.grey.shade300,
        ),
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
            backgroundImage: _memberImage != null
                ? MemoryImage(base64Decode(_memberImage!))
                : null,
            child: _memberImage == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  )
                : null,
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
    final initial = _memberName.isNotEmpty ? _memberName[0].toUpperCase() : 'A';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('Personal details')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF1B9A85),
              backgroundImage: _memberImage != null
                  ? MemoryImage(base64Decode(_memberImage!))
                  : null,
              child: _memberImage == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileDetail(_isTamil ? 'பெயர்' : 'Name', _memberName),
                  const SizedBox(height: 12),
                  _profileDetail(_isTamil ? 'தொலைபேசி' : 'Phone', _memberPhone),
                  const SizedBox(height: 12),
                  _profileDetail(
                    _isTamil ? 'குழு' : 'Group',
                    widget.group.name,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tr('Close')),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.switch_account_outlined, size: 16),
            label: Text(_isTamil ? 'சுயவிவரம் மாற்று' : 'Switch profile'),
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
    String? tempImage = _memberImage;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final initial = _nameController.text.isNotEmpty
              ? _nameController.text[0].toUpperCase()
              : 'A';
          return AlertDialog(
            title: Text(_isTamil ? 'சுயவிவரத்தைத் திருத்து' : 'Edit profile'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFF1B9A85),
                            backgroundImage: tempImage != null
                                ? MemoryImage(base64Decode(tempImage!))
                                : null,
                            child: tempImage == null
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () async {
                                await _showImagePickerSheet(
                                  dialogContext,
                                  hasImage: tempImage != null,
                                  onImageSelected: (newImage) {
                                    setDialogState(() {
                                      tempImage = newImage;
                                    });
                                  },
                                  onImageRemoved: () {
                                    setDialogState(() {
                                      tempImage = null;
                                    });
                                  },
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () async {
                        await _showImagePickerSheet(
                          dialogContext,
                          hasImage: tempImage != null,
                          onImageSelected: (newImage) {
                            setDialogState(() {
                              tempImage = newImage;
                            });
                          },
                          onImageRemoved: () {
                            setDialogState(() {
                              tempImage = null;
                            });
                          },
                        );
                      },
                      icon: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: Text(
                        _isTamil ? 'படத்தை மாற்றுக' : 'Change photo',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: _isTamil ? 'பெயர்' : 'Name',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? (_isTamil ? 'பெயரை உள்ளிடவும்' : 'Enter a name')
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _isTamil ? 'தொலைபேசி' : 'Phone',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? (_isTamil
                                ? 'தொலைபேசி எண்ணை உள்ளிடவும்'
                                : 'Enter a phone number')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_isTamil ? 'ரத்து' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: Text(_isTamil ? 'சேமி' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    if (updated == true && mounted) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      try {
        final preferences = await SharedPreferences.getInstance();
        final nameSaved = await preferences.setString(_profileNameKey, name);
        final phoneSaved = await preferences.setString(_profilePhoneKey, phone);
        if (tempImage != null) {
          await preferences.setString(_profileImageKey, tempImage!);
        } else {
          await preferences.remove(_profileImageKey);
        }
        if (!nameSaved || !phoneSaved) {
          throw StateError('The profile changes were not saved.');
        }

        if (mounted) {
          setState(() {
            _memberName = name;
            _memberPhone = phone;
            _memberImage = tempImage;
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

  Future<void> _showImagePickerSheet(
    BuildContext context, {
    required bool hasImage,
    required ValueChanged<String> onImageSelected,
    required VoidCallback onImageRemoved,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  _isTamil
                      ? 'கேலரியில் இருந்து படம் தேர்வு செய்'
                      : 'Choose photo from device',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    final file = await FilePicker.pickFile(
                      type: FileType.image,
                    );
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      if (!mounted) return;
                      final cropped = await Navigator.push<Uint8List>(
                        this.context,
                        MaterialPageRoute(
                          builder: (_) => _CropScreen(imageBytes: bytes),
                        ),
                      );
                      if (cropped != null)
                        onImageSelected(base64Encode(cropped));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isTamil
                                ? 'படம் ஏற்றுவதில் பிழை: $e'
                                : 'Error picking image: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    _isTamil ? 'படத்தை நீக்கு' : 'Remove photo',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onImageRemoved();
                  },
                ),
            ],
          ),
        ),
      ),
    );
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
            AppIcons.home,
            AppIcons.homeActive,
            'Home',
            AppColors.accent,
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            1,
            AppIcons.chat,
            AppIcons.chatActive,
            'Chat',
            AppColors.brandBlue,
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            2,
            Icons.campaign_outlined,
            Icons.campaign,
            'Notices',
            AppColors.warning,
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            3,
            AppIcons.meetings,
            AppIcons.meetingsActive,
            'Meetings',
            AppColors.brandBlue,
            teal,
          ),
          const SizedBox(height: 6),
          _buildSidebarNavItem(
            4,
            AppIcons.library,
            AppIcons.libraryActive,
            'Library',
            AppColors.brandGreen,
            teal,
          ),
          const Spacer(),
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
    Color iconColor,
    Color teal,
  ) {
    final isSelected = _index == index;
    final textColor = _isDarkMode ? AppColors.inkDark : AppColors.inkLight;

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
              color: isSelected ? Colors.white : iconColor,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    Color iconColor,
    Color teal,
  ) {
    final isSelected = _index == index;
    final textColor = _isDarkMode ? AppColors.inkDark : AppColors.inkLight;

    return ListTile(
      dense: true,
      minTileHeight: 50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: isSelected,
      selectedTileColor: _isDarkMode
          ? teal.withValues(alpha: 0.18)
          : AppColors.surfaceLight,
      leading: Icon(
        isSelected ? activeIcon : icon,
        size: 24,
        color: isSelected ? teal : iconColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
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
  final bool isDark;

  const _HomeTab({
    required this.member,
    required this.group,
    required this.isTamil,
    required this.isDark,
  });

  String _tr(String value) => AppSettings.instance.tr(value);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final notices = MockDb.notices.where((n) => n.groupId == group.id).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        Text(
          member.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ).copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: 12),
        Text(
          _tr('Notice board'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ).copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: 4),
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
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF374151)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      _tr(n.title),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _tr(n.body),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 20),
        Material(
          color: Colors.transparent,
          child: TimetableBoard(
            group: group,
            member: member,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 20),
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

class _CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const _CropScreen({required this.imageBytes});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final CropController _controller = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop photo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _cropping
                ? null
                : () {
                    setState(() => _cropping = true);
                    _controller.cropCircle();
                  },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _controller,
        aspectRatio: 1,
        withCircleUi: true,
        interactive: true,
        onCropped: (result) {
          switch (result) {
            case CropSuccess(:final croppedImage):
              Navigator.pop(context, croppedImage);
            case CropFailure(:final cause):
              setState(() => _cropping = false);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Crop failed: $cause')));
          }
        },
      ),
    );
  }
}
