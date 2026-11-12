import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg_1',
      senderName: 'Academic Coordinator',
      text:
          'Good morning everyone! Please make sure to download the Calculus assignment from the Library tab before today\'s 5:30 PM session.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isMe: false,
    ),
    ChatMessage(
      id: 'msg_2',
      senderName: 'Kavindu Perera',
      text:
          'Thank you Sir! Is the formula cheat sheet included in the same folder?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      isMe: false,
    ),
    ChatMessage(
      id: 'msg_3',
      senderName: 'You',
      text:
          'Yes Kavindu, both the assignment set and the formula sheet are uploaded in the Combined Mathematics folder.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      isMe: true,
    ),
    ChatMessage(
      id: 'msg_4',
      senderName: 'Senthil Kumar',
      text: 'Will there be a live recording uploaded after the session?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isMe: false,
    ),
  ];

  static const _channelName = 'Advanced Mathematics Cohort 2026';
  int _selectedTab = 2;
  bool _isChannelOpen = false;

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'You',
          text: text,
          timestamp: DateTime.now(),
          isMe: true,
        ),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        if (compact && _isChannelOpen) {
          return _buildConversation(context, compact: true);
        }
        if (compact) return _buildMobileInbox(context);
        return _buildWideInbox(context);
      },
    );
  }

  Widget _buildMobileInbox(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildInboxHeader(context, isTamil),
        _buildSearchField(isTamil, isDark),
        _buildTabs(context, isTamil),
        Expanded(child: _buildMobileList(context, isTamil)),
        _buildProfileStatus(context, isTamil),
      ],
    );
  }

  Widget _buildWideInbox(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  fontSize: 14,
                ),
                children: const [
                  TextSpan(text: 'safran  /  '),
                  TextSpan(
                    text: 'Chat',
                    style: TextStyle(
                      color: AppColors.headingLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: Border.all(
                  color: isDark ? AppColors.lineDark : AppColors.lineLight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 420,
                    child: Column(
                      children: [
                        _buildInboxHeader(context, isTamil),
                        _buildSearchField(isTamil, isDark),
                        _buildTabs(context, isTamil),
                        Expanded(child: _buildWideList(context, isTamil)),
                        _buildProfileStatus(context, isTamil),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? AppColors.lineDark : AppColors.lineLight,
                  ),
                  Expanded(
                    child: _isChannelOpen
                        ? _buildConversation(context)
                        : _buildEmptyConversation(context, isTamil),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxHeader(BuildContext context, bool isTamil) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isTamil ? 'அரட்டை' : 'Chat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: isTamil ? 'சேனல்கள்' : 'Channels',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              AppIcons.groups,
              color: _selectedTab == 1
                  ? AppColors.accent
                  : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
            ),
            onPressed: () => setState(() => _selectedTab = 1),
          ),
          IconButton(
            tooltip: isTamil ? 'புதிய அரட்டை' : 'New chat',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              AppIcons.conversation,
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
            onPressed: () => setState(() => _selectedTab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isTamil, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: isTamil ? 'தேடுங்கள்' : 'Search',
            hintStyle: TextStyle(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              fontSize: 14,
            ),
            prefixIcon: const Icon(AppIcons.search, size: 19),
            prefixIconColor: isDark
                ? AppColors.mutedDark
                : AppColors.mutedLight,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, bool isTamil) {
    final labels = isTamil
        ? ['படிக்காதவை', 'சேனல்கள்', 'அரட்டைகள்']
        : ['Unread', 'Channels', 'Chats'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: selected
                  ? AppColors.accent
                  : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _selectedTab = index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.inkDark
                                : AppColors.mutedLight),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, bool isTamil) {
    if (_selectedTab == 1) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        children: [_buildChannelTile(context, isTamil)],
      );
    }

    return _buildInboxEmpty(context, isTamil);
  }

  Widget _buildWideList(BuildContext context, bool isTamil) {
    if (_selectedTab == 1) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        children: [_buildChannelTile(context, isTamil)],
      );
    }

    return _buildInboxEmpty(context, isTamil);
  }

  Widget _buildChannelTile(BuildContext context, bool isTamil) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: _isChannelOpen,
      selectedTileColor: isDark
          ? AppColors.accent.withValues(alpha: 0.18)
          : AppColors.accentLight,
      leading: CircleAvatar(
        backgroundColor: AppColors.accentLight,
        child: const Icon(Icons.tag, color: AppColors.accent, size: 20),
      ),
      title: Text(
        _channelName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isTamil ? '42 பேர் செயலில்' : '42 active',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () => setState(() => _isChannelOpen = true),
    );
  }

  Widget _buildInboxEmpty(BuildContext context, bool isTamil) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _selectedTab == 0
              ? (isTamil
                    ? 'படிக்காத செய்திகள் இல்லை.'
                    : 'You’re all caught up.')
              : (isTamil
                    ? 'இன்னும் அரட்டைகள் இல்லை. உரையாடலைத் தொடங்குங்கள்.'
                    : 'No chats yet. Start a conversation.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.mutedDark
                : AppColors.mutedLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatus(BuildContext context, bool isTamil) {
    final session = ref.watch(sessionProvider);
    final displayName = session?.user.displayName.trim().isNotEmpty == true
        ? session!.user.displayName
        : 'Airo Techhub Member';
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showStatusMenu(context, displayName, initials),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.lineDark : AppColors.lineLight,
            ),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accentLight,
                  child: Text(
                    initials.isEmpty ? 'A' : initials,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isTamil ? 'செயலில்' : 'Available',
                    style: const TextStyle(
                      color: AppColors.mutedLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.mutedLight,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatusMenu(
    BuildContext context,
    String displayName,
    String initials,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final anchor = context.findRenderObject() as RenderBox;
    final topLeft = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = anchor.localToGlobal(
      anchor.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      constraints: const BoxConstraints(minWidth: 310, maxWidth: 655),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          height: 74,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accentLight,
                child: Text(
                  initials.isEmpty ? 'A' : initials,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Admin',
                    style: TextStyle(color: AppColors.mutedLight),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          child: _StatusMenuRow(
            color: AppColors.success,
            label: 'Available',
            selected: true,
          ),
        ),
        const PopupMenuItem(
          child: _StatusMenuRow(color: Colors.redAccent, label: 'Busy'),
        ),
        const PopupMenuItem(
          child: _StatusMenuRow(
            color: Colors.red,
            label: 'Do not disturb',
            showMinus: true,
          ),
        ),
        const PopupMenuItem(
          child: _StatusMenuRow(color: Colors.amber, label: 'Be right back'),
        ),
        const PopupMenuItem(
          child: _StatusMenuRow(color: Colors.amber, label: 'Appear away'),
        ),
        const PopupMenuItem(
          child: _StatusMenuRow(
            color: Color(0xFF94A3B8),
            label: 'Appear offline',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          child: Text(
            'Reset status',
            style: TextStyle(color: AppColors.mutedLight),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyConversation(BuildContext context, bool isTamil) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.conversation,
              size: 44,
              color: isDark ? AppColors.mutedDark : AppColors.lineLight,
            ),
            const SizedBox(height: 14),
            Text(
              isTamil
                  ? 'செய்தி அனுப்ப அரட்டையைத் தேர்ந்தெடுக்கவும்'
                  : 'Pick a chat to start messaging',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              isTamil
                  ? 'அரட்டையைத் தொடங்கவும், சேனலை உருவாக்கவும் அல்லது பட்டியலிலிருந்து உரையாடலைத் திறக்கவும்.'
                  : 'Start a chat, create a channel, or open a conversation from the list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation(BuildContext context, {bool compact = false}) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(compact ? 8 : 16, 8, 12, 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.lineDark : AppColors.lineLight,
              ),
            ),
          ),
          child: Row(
            children: [
              if (compact)
                IconButton(
                  tooltip: isTamil ? 'பின்னால்' : 'Back to chats',
                  icon: const Icon(AppIcons.back),
                  onPressed: () => setState(() => _isChannelOpen = false),
                ),
              const Icon(Icons.tag, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  _channelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTamil ? '42 செயலில்' : '42 active',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) =>
                _buildMessageBubble(context, _messages[index], isDark),
          ),
        ),
        _buildMessageComposer(context, isTamil, isDark),
      ],
    );
  }

  Widget _buildMessageComposer(
    BuildContext context,
    bool isTamil,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.lineLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: isTamil ? 'கோப்பை இணைக்கவும்' : 'Attach file',
              icon: const Icon(AppIcons.attach, color: AppColors.mutedLight),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isTamil
                          ? 'கோப்பு இணைப்பு விரைவில் கிடைக்கும்.'
                          : 'File attachments are coming soon.',
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: isTamil
                      ? 'செய்தியை உள்ளிடவும்...'
                      : 'Type a message...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: isTamil ? 'அனுப்பு' : 'Send message',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(AppIcons.send, size: 18),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage msg,
    bool isDark,
  ) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe
              ? AppColors.accent
              : (isDark ? AppColors.cardDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: msg.isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: msg.isMe
              ? null
              : Border.all(
                  color: isDark ? AppColors.lineDark : AppColors.lineLight,
                ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!msg.isMe) ...[
              Text(
                msg.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe
                    ? Colors.white
                    : (isDark ? AppColors.inkDark : AppColors.inkLight),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: msg.isMe ? Colors.white70 : AppColors.mutedLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMenuRow extends StatelessWidget {
  const _StatusMenuRow({
    required this.color,
    required this.label,
    this.selected = false,
    this.showMinus = false,
  });

  final Color color;
  final String label;
  final bool selected;
  final bool showMinus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: showMinus
              ? const Icon(Icons.remove, color: Colors.white, size: 15)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label)),
        Icon(
          selected ? Icons.check : Icons.chevron_right,
          color: selected ? AppColors.accent : AppColors.mutedLight,
          size: 20,
        ),
      ],
    );
  }
}
